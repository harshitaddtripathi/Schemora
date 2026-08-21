import os
import json
import csv
import logging
from abc import ABC, abstractmethod
from pathlib import Path
from typing import List, Dict, Any, Optional

logger = logging.getLogger("schemora.data_pipeline")


class SchemeDataSource(ABC):
    """Abstract Base Class for pluggable scheme data sources."""

    @abstractmethod
    def fetch_schemes(self) -> List[Dict[str, Any]]:
        """Fetch raw scheme records from source."""
        pass


class MySchemeAuthorizedSource(SchemeDataSource):
    """Official authorized myScheme API / Data Feed adapter."""

    def __init__(self, api_url: Optional[str] = None, api_key: Optional[str] = None):
        self.api_url = api_url or os.getenv("MYSCHEME_API_URL", "")
        self.api_key = api_key or os.getenv("MYSCHEME_API_KEY", "")

    def fetch_schemes(self) -> List[Dict[str, Any]]:
        if not self.api_url or not self.api_key:
            logger.warning(
                "MySchemeAuthorizedSource: No authorized API credentials (MYSCHEME_API_URL / MYSCHEME_API_KEY) found. "
                "Skipping live API fetch. Automated web scraping is disabled in compliance with Terms of Use."
            )
            return []

        logger.info(f"Fetching scheme records from authorized myScheme API at {self.api_url}")
        # In a production environment with valid API key, execute HTTP GET/POST to official endpoint.
        try:
            import httpx
            headers = {"Authorization": f"Bearer {self.api_key}", "Accept": "application/json"}
            response = httpx.get(self.api_url, headers=headers, timeout=30.0)
            if response.status_code == 200:
                data = response.json()
                records = data.get("schemes", data if isinstance(data, list) else [])
                logger.info(f"Successfully fetched {len(records)} schemes from myScheme API.")
                return [
                    {
                        "source": "myScheme",
                        "source_id": str(r.get("id") or r.get("scheme_id") or ""),
                        "raw_data": r,
                    }
                    for r in records
                ]
            else:
                logger.error(f"myScheme API returned status code {response.status_code}")
                return []
        except Exception as e:
            logger.error(f"Error fetching from myScheme API: {e}")
            return []


class DataGovSource(SchemeDataSource):
    """Data.gov.in official open data feed adapter."""

    def __init__(self, api_key: Optional[str] = None, resource_id: Optional[str] = None):
        self.api_key = api_key or os.getenv("DATA_GOV_API_KEY", "")
        self.resource_id = resource_id or os.getenv("DATA_GOV_RESOURCE_ID", "")

    def fetch_schemes(self) -> List[Dict[str, Any]]:
        if not self.api_key or not self.resource_id:
            logger.info("DataGovSource: DATA_GOV_API_KEY or DATA_GOV_RESOURCE_ID not configured. Skipping.")
            return []

        url = f"https://api.data.gov.in/resource/{self.resource_id}?api-key={self.api_key}&format=json&limit=1000"
        logger.info("Fetching schemes from Data.gov.in API...")
        try:
            import httpx
            response = httpx.get(url, timeout=30.0)
            if response.status_code == 200:
                data = response.json()
                records = data.get("records", [])
                logger.info(f"Fetched {len(records)} records from Data.gov.in")
                return [
                    {
                        "source": "data.gov.in",
                        "source_id": str(r.get("id") or r.get("index") or f"datagov-{idx}"),
                        "raw_data": r,
                    }
                    for idx, r in enumerate(records)
                ]
        except Exception as e:
            logger.error(f"Error fetching from Data.gov.in: {e}")
        return []


class OfficialMinistrySource(SchemeDataSource):
    """Adapter for official central ministry feeds."""

    def __init__(self, feed_urls: Optional[List[str]] = None):
        self.feed_urls = feed_urls or []

    def fetch_schemes(self) -> List[Dict[str, Any]]:
        results = []
        for url in self.feed_urls:
            try:
                import httpx
                res = httpx.get(url, timeout=30.0)
                if res.status_code == 200:
                    data = res.json()
                    items = data.get("schemes", data if isinstance(data, list) else [])
                    for item in items:
                        results.append({
                            "source": "OfficialMinistry",
                            "source_id": str(item.get("scheme_id") or item.get("id") or ""),
                            "raw_data": item,
                        })
            except Exception as e:
                logger.error(f"Error fetching ministry feed from {url}: {e}")
        return results


class OfficialStateSource(SchemeDataSource):
    """Adapter for state government open portals."""

    def __init__(self, state_name: str, feed_url: Optional[str] = None):
        self.state_name = state_name
        self.feed_url = feed_url

    def fetch_schemes(self) -> List[Dict[str, Any]]:
        if not self.feed_url:
            return []
        try:
            import httpx
            res = httpx.get(self.feed_url, timeout=30.0)
            if res.status_code == 200:
                data = res.json()
                items = data if isinstance(data, list) else data.get("data", [])
                return [
                    {
                        "source": f"StateOfficial-{self.state_name}",
                        "source_id": str(item.get("id") or item.get("scheme_id") or ""),
                        "raw_data": item,
                    }
                    for item in items
                ]
        except Exception as e:
            logger.error(f"Error fetching state feed for {self.state_name}: {e}")
        return []


class LocalRawFileSource(SchemeDataSource):
    """Adapter to load authorized JSON / CSV export files from disk."""

    def __init__(self, file_paths: Optional[List[Path]] = None):
        self.file_paths = file_paths or []

    def fetch_schemes(self) -> List[Dict[str, Any]]:
        results = []
        for fp in self.file_paths:
            if not fp.exists():
                logger.warning(f"Local file {fp} does not exist. Skipping.")
                continue

            logger.info(f"Loading local raw source file: {fp}")
            if fp.suffix.lower() == ".json":
                try:
                    with open(fp, "r", encoding="utf-8") as f:
                        content = json.load(f)
                        records = content if isinstance(content, list) else content.get("schemes", [content])
                        for r in records:
                            # If record is already wrapped in source format
                            if isinstance(r, dict) and "raw_data" in r:
                                results.append(r)
                            else:
                                src_name = r.get("source") or "LocalAuthorizedExport"
                                src_id = str(r.get("scheme_id") or r.get("id") or r.get("source_id") or "")
                                results.append({
                                    "source": src_name,
                                    "source_id": src_id,
                                    "raw_data": r,
                                })
                except Exception as e:
                    logger.error(f"Failed to parse JSON file {fp}: {e}")

            elif fp.suffix.lower() == ".csv":
                try:
                    with open(fp, "r", encoding="utf-8-sig") as f:
                        reader = csv.DictReader(f)
                        for idx, row in enumerate(reader):
                            src_id = row.get("scheme_id") or row.get("id") or f"csv-{idx}"
                            results.append({
                                "source": "LocalCSVExport",
                                "source_id": str(src_id),
                                "raw_data": dict(row),
                            })
                except Exception as e:
                    logger.error(f"Failed to parse CSV file {fp}: {e}")

        logger.info(f"LocalRawFileSource loaded {len(results)} total records.")
        return results
