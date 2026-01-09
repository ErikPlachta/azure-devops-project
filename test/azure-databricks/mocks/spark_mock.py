"""Mock SparkSession for local development and testing.

Provides MockSparkSession and MockDataFrame that simulate
basic Spark behavior for offline development.
"""

from __future__ import annotations

import json
from collections.abc import Callable
from dataclasses import dataclass, field
from typing import Any

# Singleton instance
_mock_spark: MockSparkSession | None = None


@dataclass
class MockRow:
    """Mock Spark Row."""

    _data: dict[str, Any] = field(default_factory=dict)

    def __getattr__(self, name: str) -> Any:
        if name.startswith("_"):
            return super().__getattribute__(name)
        return self._data.get(name)

    def __getitem__(self, key: str | int) -> Any:
        if isinstance(key, int):
            return list(self._data.values())[key]
        return self._data[key]

    def asDict(self, recursive: bool = False) -> dict[str, Any]:
        """Convert row to dictionary."""
        return dict(self._data)


def Row(**kwargs: Any) -> MockRow:
    """Create a mock Row (mimics pyspark.sql.Row)."""
    return MockRow(_data=kwargs)


@dataclass
class MockColumn:
    """Mock Spark Column for expressions."""

    name: str

    def alias(self, name: str) -> MockColumn:
        """Create aliased column."""
        return MockColumn(name=name)

    def asc(self) -> MockColumn:
        """Ascending sort."""
        return self

    def desc(self) -> MockColumn:
        """Descending sort."""
        return self

    def isNull(self) -> MockColumn:
        """Check for null."""
        return self

    def isNotNull(self) -> MockColumn:
        """Check for not null."""
        return self

    def __eq__(self, other: Any) -> MockColumn:  # type: ignore[override]
        return self

    def __ne__(self, other: Any) -> MockColumn:  # type: ignore[override]
        return self

    def __gt__(self, other: Any) -> MockColumn:
        return self

    def __lt__(self, other: Any) -> MockColumn:
        return self

    def __ge__(self, other: Any) -> MockColumn:
        return self

    def __le__(self, other: Any) -> MockColumn:
        return self


class MockDataFrame:
    """Mock Spark DataFrame."""

    def __init__(self, data: list[dict[str, Any]] | None = None) -> None:
        self._data: list[dict[str, Any]] = data or []
        self._schema: list[str] = []
        if self._data:
            self._schema = list(self._data[0].keys())

    def collect(self) -> list[MockRow]:
        """Collect all rows."""
        return [MockRow(_data=row) for row in self._data]

    def take(self, n: int) -> list[MockRow]:
        """Take first n rows."""
        return [MockRow(_data=row) for row in self._data[:n]]

    def first(self) -> MockRow | None:
        """Get first row."""
        if self._data:
            return MockRow(_data=self._data[0])
        return None

    def count(self) -> int:
        """Count rows."""
        return len(self._data)

    def show(self, n: int = 20, truncate: bool = True) -> None:
        """Display rows (prints to stdout)."""
        import pprint

        pprint.pprint(self._data[:n])

    def select(self, *cols: str | MockColumn) -> MockDataFrame:
        """Select columns."""
        col_names = [c.name if isinstance(c, MockColumn) else c for c in cols]
        new_data = [{k: row.get(k) for k in col_names} for row in self._data]
        return MockDataFrame(new_data)

    def filter(self, condition: Any) -> MockDataFrame:
        """Filter rows (returns same data in mock)."""
        return MockDataFrame(list(self._data))

    def where(self, condition: Any) -> MockDataFrame:
        """Alias for filter."""
        return self.filter(condition)

    def limit(self, n: int) -> MockDataFrame:
        """Limit rows."""
        return MockDataFrame(self._data[:n])

    def orderBy(self, *cols: str | MockColumn) -> MockDataFrame:
        """Order by columns (no-op in mock)."""
        return MockDataFrame(list(self._data))

    def groupBy(self, *cols: str | MockColumn) -> MockGroupedData:
        """Group by columns."""
        return MockGroupedData(self)

    def join(
        self,
        other: MockDataFrame,
        on: str | list[str] | None = None,
        how: str = "inner",
    ) -> MockDataFrame:
        """Join with another DataFrame (returns self in mock)."""
        return MockDataFrame(list(self._data))

    def union(self, other: MockDataFrame) -> MockDataFrame:
        """Union with another DataFrame."""
        return MockDataFrame(self._data + other._data)

    def distinct(self) -> MockDataFrame:
        """Get distinct rows."""
        seen: set[str] = set()
        unique: list[dict[str, Any]] = []
        for row in self._data:
            key = json.dumps(row, sort_keys=True, default=str)
            if key not in seen:
                seen.add(key)
                unique.append(row)
        return MockDataFrame(unique)

    def dropDuplicates(self, subset: list[str] | None = None) -> MockDataFrame:
        """Drop duplicate rows."""
        return self.distinct()

    def withColumn(self, name: str, col: Any) -> MockDataFrame:
        """Add or replace column."""
        new_data = [{**row, name: None} for row in self._data]
        return MockDataFrame(new_data)

    def withColumnRenamed(self, existing: str, new: str) -> MockDataFrame:
        """Rename column."""
        new_data = []
        for row in self._data:
            new_row = {(new if k == existing else k): v for k, v in row.items()}
            new_data.append(new_row)
        return MockDataFrame(new_data)

    def drop(self, *cols: str) -> MockDataFrame:
        """Drop columns."""
        cols_set = set(cols)
        new_data = [{k: v for k, v in row.items() if k not in cols_set} for row in self._data]
        return MockDataFrame(new_data)

    def toPandas(self) -> Any:
        """Convert to pandas DataFrame."""
        try:
            import pandas as pd

            return pd.DataFrame(self._data)
        except ImportError as err:
            raise ImportError("pandas is required for toPandas()") from err

    def toJSON(self) -> MockRDD:
        """Convert to JSON RDD."""
        return MockRDD([json.dumps(row) for row in self._data])

    @property
    def columns(self) -> list[str]:
        """Get column names."""
        return self._schema

    @property
    def schema(self) -> MockSchema:
        """Get schema."""
        return MockSchema(self._schema)

    def printSchema(self) -> None:
        """Print schema."""
        print("root")
        for col in self._schema:
            print(f" |-- {col}: string (nullable = true)")

    def cache(self) -> MockDataFrame:
        """Cache DataFrame (no-op in mock)."""
        return self

    def persist(self, storageLevel: Any = None) -> MockDataFrame:
        """Persist DataFrame (no-op in mock)."""
        return self

    def unpersist(self, blocking: bool = False) -> MockDataFrame:
        """Unpersist DataFrame (no-op in mock)."""
        return self

    def createOrReplaceTempView(self, name: str) -> None:
        """Create temp view."""
        spark = get_mock_spark()
        spark._temp_views[name] = self

    @property
    def write(self) -> MockDataFrameWriter:
        """Get DataFrameWriter."""
        return MockDataFrameWriter(self)


class MockGroupedData:
    """Mock grouped DataFrame."""

    def __init__(self, df: MockDataFrame) -> None:
        self._df = df

    def count(self) -> MockDataFrame:
        """Count per group."""
        return MockDataFrame([{"count": len(self._df._data)}])

    def sum(self, *cols: str) -> MockDataFrame:
        """Sum per group."""
        return MockDataFrame([dict.fromkeys(cols, 0)])

    def avg(self, *cols: str) -> MockDataFrame:
        """Average per group."""
        return MockDataFrame([dict.fromkeys(cols, 0.0)])

    def agg(self, *exprs: Any) -> MockDataFrame:
        """Aggregate."""
        return MockDataFrame([{}])


class MockDataFrameWriter:
    """Mock DataFrameWriter for write operations."""

    def __init__(self, df: MockDataFrame) -> None:
        self._df = df
        self._format: str = "parquet"
        self._mode: str = "error"
        self._options: dict[str, Any] = {}
        self._partition_by: list[str] = []

    def format(self, source: str) -> MockDataFrameWriter:
        """Set format."""
        self._format = source
        return self

    def mode(self, saveMode: str) -> MockDataFrameWriter:
        """Set save mode."""
        self._mode = saveMode
        return self

    def option(self, key: str, value: Any) -> MockDataFrameWriter:
        """Set option."""
        self._options[key] = value
        return self

    def options(self, **options: Any) -> MockDataFrameWriter:
        """Set multiple options."""
        self._options.update(options)
        return self

    def partitionBy(self, *cols: str) -> MockDataFrameWriter:
        """Set partition columns."""
        self._partition_by = list(cols)
        return self

    def save(self, path: str) -> None:
        """Save to path (no-op in mock)."""
        pass

    def saveAsTable(self, name: str) -> None:
        """Save as table (stores in mock catalog)."""
        spark = get_mock_spark()
        spark._tables[name] = self._df

    def insertInto(self, tableName: str, overwrite: bool = False) -> None:
        """Insert into table."""
        spark = get_mock_spark()
        if tableName in spark._tables and not overwrite:
            existing = spark._tables[tableName]
            spark._tables[tableName] = MockDataFrame(existing._data + self._df._data)
        else:
            spark._tables[tableName] = self._df


class MockRDD:
    """Mock RDD."""

    def __init__(self, data: list[Any]) -> None:
        self._data = data

    def collect(self) -> list[Any]:
        """Collect all elements."""
        return self._data

    def take(self, n: int) -> list[Any]:
        """Take first n elements."""
        return self._data[:n]

    def count(self) -> int:
        """Count elements."""
        return len(self._data)

    def map(self, f: Callable[[Any], Any]) -> MockRDD:
        """Map function over elements."""
        return MockRDD([f(x) for x in self._data])

    def filter(self, f: Callable[[Any], bool]) -> MockRDD:
        """Filter elements."""
        return MockRDD([x for x in self._data if f(x)])


@dataclass
class MockSchema:
    """Mock DataFrame schema."""

    _fields: list[str]

    @property
    def names(self) -> list[str]:
        """Get field names."""
        return self._fields

    @property
    def fields(self) -> list[MockStructField]:
        """Get fields."""
        return [MockStructField(name=f) for f in self._fields]


@dataclass
class MockStructField:
    """Mock schema field."""

    name: str
    dataType: str = "StringType"
    nullable: bool = True


class MockSparkSession:
    """Mock SparkSession."""

    def __init__(self) -> None:
        self._tables: dict[str, MockDataFrame] = {}
        self._temp_views: dict[str, MockDataFrame] = {}
        self._sql_handlers: dict[str, Callable[[str], MockDataFrame]] = {}
        self._conf = MockSparkConf()

    def sql(self, query: str) -> MockDataFrame:
        """Execute SQL query.

        Checks registered handlers first, then temp views, then returns empty DataFrame.
        """
        # Check for registered SQL handlers
        for pattern, handler in self._sql_handlers.items():
            if pattern in query:
                return handler(query)

        # Check temp views
        for view_name, df in self._temp_views.items():
            if view_name in query:
                return df

        # Check tables
        for table_name, df in self._tables.items():
            if table_name in query:
                return df

        # Default: return empty DataFrame
        return MockDataFrame([])

    def table(self, tableName: str) -> MockDataFrame:
        """Get table by name."""
        if tableName in self._tables:
            return self._tables[tableName]
        if tableName in self._temp_views:
            return self._temp_views[tableName]
        return MockDataFrame([])

    def createDataFrame(
        self,
        data: list[Any] | Any,
        schema: list[str] | None = None,
    ) -> MockDataFrame:
        """Create DataFrame from data."""
        if hasattr(data, "to_dict"):
            # pandas DataFrame
            data = data.to_dict(orient="records")
        elif not isinstance(data, list):
            data = list(data)

        # Convert Row objects to dicts
        processed = []
        for row in data:
            if isinstance(row, MockRow):
                processed.append(row.asDict())
            elif isinstance(row, dict):
                processed.append(row)
            elif hasattr(row, "_asdict"):  # namedtuple
                processed.append(row._asdict())
            elif isinstance(row, (list, tuple)) and schema:
                processed.append(dict(zip(schema, row, strict=False)))
            else:
                processed.append({"value": row})

        return MockDataFrame(processed)

    @property
    def conf(self) -> MockSparkConf:
        """Get Spark configuration."""
        return self._conf

    @property
    def catalog(self) -> MockCatalog:
        """Get catalog."""
        return MockCatalog(self)

    @property
    def read(self) -> MockDataFrameReader:
        """Get DataFrameReader."""
        return MockDataFrameReader(self)

    # Test helpers
    def register_table(self, name: str, data: list[dict[str, Any]]) -> None:
        """Register mock table (for testing)."""
        self._tables[name] = MockDataFrame(data)

    def register_sql_handler(self, pattern: str, handler: Callable[[str], MockDataFrame]) -> None:
        """Register SQL query handler (for testing)."""
        self._sql_handlers[pattern] = handler

    def clear_tables(self) -> None:
        """Clear all tables and views."""
        self._tables.clear()
        self._temp_views.clear()

    def clear_handlers(self) -> None:
        """Clear SQL handlers."""
        self._sql_handlers.clear()

    def reset(self) -> None:
        """Reset all mock state."""
        self._tables.clear()
        self._temp_views.clear()
        self._sql_handlers.clear()


class MockSparkConf:
    """Mock Spark configuration."""

    def __init__(self) -> None:
        self._conf: dict[str, str] = {}

    def get(self, key: str, default: str | None = None) -> str | None:
        """Get configuration value."""
        return self._conf.get(key, default)

    def set(self, key: str, value: str) -> MockSparkConf:
        """Set configuration value."""
        self._conf[key] = value
        return self


class MockCatalog:
    """Mock Spark catalog."""

    def __init__(self, spark: MockSparkSession) -> None:
        self._spark = spark

    def listTables(self, dbName: str | None = None) -> list[dict[str, Any]]:
        """List tables."""
        return [{"name": name, "database": dbName} for name in self._spark._tables.keys()]

    def tableExists(self, tableName: str, dbName: str | None = None) -> bool:
        """Check if table exists."""
        return tableName in self._spark._tables


class MockDataFrameReader:
    """Mock DataFrameReader."""

    def __init__(self, spark: MockSparkSession) -> None:
        self._spark = spark
        self._format: str = "parquet"
        self._options: dict[str, Any] = {}

    def format(self, source: str) -> MockDataFrameReader:
        """Set format."""
        self._format = source
        return self

    def option(self, key: str, value: Any) -> MockDataFrameReader:
        """Set option."""
        self._options[key] = value
        return self

    def options(self, **options: Any) -> MockDataFrameReader:
        """Set multiple options."""
        self._options.update(options)
        return self

    def load(self, path: str) -> MockDataFrame:
        """Load from path (returns empty DataFrame in mock)."""
        return MockDataFrame([])

    def table(self, tableName: str) -> MockDataFrame:
        """Load table."""
        return self._spark.table(tableName)

    def json(self, path: str) -> MockDataFrame:
        """Load JSON file."""
        return MockDataFrame([])

    def parquet(self, path: str) -> MockDataFrame:
        """Load Parquet file."""
        return MockDataFrame([])

    def csv(self, path: str) -> MockDataFrame:
        """Load CSV file."""
        return MockDataFrame([])


def get_mock_spark() -> MockSparkSession:
    """Get singleton MockSparkSession instance."""
    global _mock_spark
    if _mock_spark is None:
        _mock_spark = MockSparkSession()
    return _mock_spark


def reset_mock_spark() -> None:
    """Reset singleton MockSparkSession instance."""
    global _mock_spark
    if _mock_spark is not None:
        _mock_spark.reset()
    else:
        _mock_spark = MockSparkSession()
