import csv
import json
import os
import re
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib.parse import parse_qs, urljoin, urlparse

import mysql.connector
import requests
from bs4 import BeautifulSoup
from mysql.connector import Error


BASE_URL = "https://water.sabah.gov.my/products?page=0"
OUTPUT_DIR = Path("data")


@dataclass
class ProductRecord:
	no: int
	page: int
	supplier_agent: str
	supplier_valid_until: Optional[str]
	product_materials: str
	product_type: str
	classification: str
	brand: str
	attachment_urls: List[str]
	source_url: str


def fetch_html(url: str, timeout: int = 30) -> str:
	response = requests.get(url, timeout=timeout)
	response.raise_for_status()
	return response.text


def extract_page_numbers(soup: BeautifulSoup) -> List[int]:
	pages: set[int] = {0}
	for link in soup.select("a[href*='products?page=']"):
		href = link.get("href", "")
		full = urljoin("https://water.sabah.gov.my/", href)
		query_page = parse_qs(urlparse(full).query).get("page")
		if query_page and query_page[0].isdigit():
			pages.add(int(query_page[0]))
	return sorted(pages)


def split_supplier_and_validity(raw: str) -> Tuple[str, Optional[str]]:
	match = re.search(r"Valid\s+until:\s*([0-9]{2}-[0-9]{2}-[0-9]{4})", raw, flags=re.IGNORECASE)
	if not match:
		return raw.strip(), None
	valid_until = match.group(1)
	supplier = raw[:match.start()].strip()
	return supplier, valid_until


def parse_page(html: str, page: int, source_url: str) -> List[ProductRecord]:
	soup = BeautifulSoup(html, "html.parser")
	records: List[ProductRecord] = []

	for row in soup.select("table tr"):
		cells = row.find_all("td")
		if len(cells) < 7:
			continue

		idx_text = cells[0].get_text(" ", strip=True).replace(".", "")
		if not idx_text.isdigit():
			continue

		supplier_raw = cells[1].get_text(" ", strip=True)
		supplier, valid_until = split_supplier_and_validity(supplier_raw)
		attachments = []
		for a_tag in cells[-1].find_all("a", href=True):
			attachments.append(urljoin("https://water.sabah.gov.my/", a_tag["href"]))

		records.append(
			ProductRecord(
				no=int(idx_text),
				page=page,
				supplier_agent=supplier,
				supplier_valid_until=valid_until,
				product_materials=cells[2].get_text(" ", strip=True),
				product_type=cells[3].get_text(" ", strip=True),
				classification=cells[4].get_text(" ", strip=True),
				brand=cells[5].get_text(" ", strip=True),
				attachment_urls=attachments,
				source_url=source_url,
			)
		)

	return records


def scrape_all_pages(base_url: str = BASE_URL) -> List[ProductRecord]:
	all_records: List[ProductRecord] = []
	page = 0
	while True:
		url = f"https://water.sabah.gov.my/products?page={page}"
		html = fetch_html(url)
		page_records = parse_page(html=html, page=page, source_url=url)
		if not page_records:
			break
		all_records.extend(page_records)
		page += 1

	all_records.sort(key=lambda r: r.no)
	return all_records


def save_outputs(records: List[ProductRecord], output_dir: Path = OUTPUT_DIR) -> Dict[str, Path]:
	output_dir.mkdir(parents=True, exist_ok=True)
	json_path = output_dir / "water_products.json"
	csv_path = output_dir / "water_products.csv"

	json_payload = [asdict(record) for record in records]
	json_path.write_text(json.dumps(json_payload, indent=2), encoding="utf-8")

	with csv_path.open("w", newline="", encoding="utf-8") as csv_file:
		writer = csv.DictWriter(
			csv_file,
			fieldnames=[
				"no",
				"page",
				"supplier_agent",
				"supplier_valid_until",
				"product_materials",
				"product_type",
				"classification",
				"brand",
				"attachment_urls",
				"source_url",
			],
		)
		writer.writeheader()
		for record in records:
			row = asdict(record)
			row["attachment_urls"] = " | ".join(record.attachment_urls)
			writer.writerow(row)

	return {
		"json": json_path,
		"csv": csv_path,
	}


def get_mysql_connection():
	host = os.getenv("MYSQL_HOST", "localhost")
	port = int(os.getenv("MYSQL_PORT", "3306"))
	user = os.getenv("MYSQL_USER", "root")
	password = os.getenv("MYSQL_PASSWORD", "JASSPPA@2000")
	database = os.getenv("MYSQL_DATABASE", "sistemppa")

	if not user:
		return None

	bootstrap = mysql.connector.connect(
		host=host,
		port=port,
		user=user,
		password=password,
		connection_timeout=15,
	)
	cursor = bootstrap.cursor()
	cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{database}`")
	cursor.close()
	bootstrap.close()

	return mysql.connector.connect(
		host=host,
		port=port,
		user=user,
		password=password,
		database=database,
		connection_timeout=15,
	)


def ensure_mysql_schema(connection) -> None:
	cursor = connection.cursor()
	cursor.execute(
		"""
		CREATE TABLE IF NOT EXISTS water_products (
			id INT AUTO_INCREMENT PRIMARY KEY,
			no INT NOT NULL,
			page INT NOT NULL,
			supplier_agent TEXT NOT NULL,
			supplier_valid_until DATE NULL,
			product_materials TEXT NOT NULL,
			product_type TEXT NOT NULL,
			classification TEXT NOT NULL,
			brand TEXT NOT NULL,
			attachment_urls LONGTEXT,
			source_url TEXT NOT NULL,
			UNIQUE KEY uniq_no_source (no, source_url(255))
		)
		"""
	)
	connection.commit()
	cursor.close()


def write_records_to_mysql(records: List[ProductRecord], connection) -> int:
	ensure_mysql_schema(connection)
	insert_sql = (
		"INSERT INTO water_products "
		"(no, page, supplier_agent, supplier_valid_until, product_materials, product_type, "
		"classification, brand, attachment_urls, source_url) "
		"VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s) "
		"ON DUPLICATE KEY UPDATE "
		"page=VALUES(page), supplier_agent=VALUES(supplier_agent), "
		"supplier_valid_until=VALUES(supplier_valid_until), "
		"product_materials=VALUES(product_materials), product_type=VALUES(product_type), "
		"classification=VALUES(classification), brand=VALUES(brand), "
		"attachment_urls=VALUES(attachment_urls)"
	)

	cursor = connection.cursor()
	count = 0
	for record in records:
		date_value = None
		if record.supplier_valid_until:
			dd, mm, yyyy = record.supplier_valid_until.split("-")
			date_value = f"{yyyy}-{mm}-{dd}"

		cursor.execute(
			insert_sql,
			(
				record.no,
				record.page,
				record.supplier_agent,
				date_value,
				record.product_materials,
				record.product_type,
				record.classification,
				record.brand,
				json.dumps(record.attachment_urls),
				record.source_url,
			),
		)
		count += 1

	connection.commit()
	cursor.close()
	return count


def main() -> None:
	print("Scraping Sabah water product pages...")
	records = scrape_all_pages(BASE_URL)
	files = save_outputs(records, OUTPUT_DIR)
	print(f"Saved {len(records)} records to {files['json']} and {files['csv']}")

	try:
		connection = get_mysql_connection()
		if connection is None:
			print("Skipped MySQL write: set at least MYSQL_USER")
			return
		inserted = write_records_to_mysql(records, connection)
		print(f"Upserted {inserted} records into MySQL table water_products")
	except Error as exc:
		print(f"MySQL write failed: {exc}")
	finally:
		if "connection" in locals() and connection and connection.is_connected():
			connection.close()


if __name__ == "__main__":
	main()
