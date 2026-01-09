"""
Mock Databricks Clusters API for local testing.

Provides a mock implementation of the Databricks SDK Clusters API,
enabling local development and testing without a live workspace.

Examples
--------
Use mock in tests::

    from mocks.cluster_mock import MockClustersAPI

    clusters = MockClustersAPI()
    clusters.add_cluster("cluster-123", "my-cluster", "RUNNING")
    info = clusters.get("cluster-123")
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class MockClusterState(str, Enum):
    """Mock cluster states."""

    PENDING = "PENDING"
    RUNNING = "RUNNING"
    RESTARTING = "RESTARTING"
    RESIZING = "RESIZING"
    TERMINATING = "TERMINATING"
    TERMINATED = "TERMINATED"
    ERROR = "ERROR"
    UNKNOWN = "UNKNOWN"


@dataclass
class MockClusterInfo:
    """Mock cluster info."""

    cluster_id: str
    cluster_name: str
    state: MockClusterState = MockClusterState.RUNNING
    spark_version: str = "13.3.x-scala2.12"
    node_type_id: str = "Standard_DS3_v2"
    num_workers: int = 2
    autoscale: dict[str, int] | None = None
    driver_node_type_id: str | None = None
    state_message: str = ""
    creator_user_name: str = "mock@databricks.com"
    cluster_source: str = "UI"
    default_tags: dict[str, str] = field(default_factory=dict)


@dataclass
class MockClusterList:
    """Mock cluster list response."""

    clusters: list[MockClusterInfo] = field(default_factory=list)


class MockClustersAPI:
    """
    Mock implementation of Databricks Clusters API.

    Simulates cluster management for testing.

    Examples
    --------
    Basic usage::

        clusters = MockClustersAPI()
        clusters.add_cluster("c-123", "my-cluster", "RUNNING")
        info = clusters.get("c-123")
        assert info.state == MockClusterState.RUNNING

    List clusters::

        clusters = MockClustersAPI()
        clusters.add_cluster("c-1", "cluster-1")
        clusters.add_cluster("c-2", "cluster-2")
        result = clusters.list()
        assert len(result.clusters) == 2
    """

    def __init__(self) -> None:
        """Initialize mock Clusters API."""
        self._clusters: dict[str, MockClusterInfo] = {}

    def add_cluster(
        self,
        cluster_id: str,
        cluster_name: str,
        state: str | MockClusterState = MockClusterState.RUNNING,
        **kwargs: Any,
    ) -> MockClusterInfo:
        """
        Add a mock cluster.

        Parameters
        ----------
        cluster_id : str
            Cluster ID
        cluster_name : str
            Cluster name
        state : str or MockClusterState
            Cluster state
        **kwargs
            Additional cluster attributes

        Returns
        -------
        MockClusterInfo
            Created cluster info
        """
        if isinstance(state, str):
            state = MockClusterState(state)

        cluster = MockClusterInfo(
            cluster_id=cluster_id,
            cluster_name=cluster_name,
            state=state,
            **kwargs,
        )
        self._clusters[cluster_id] = cluster
        return cluster

    def get(self, cluster_id: str) -> MockClusterInfo:
        """
        Get cluster info.

        Parameters
        ----------
        cluster_id : str
            Cluster ID

        Returns
        -------
        MockClusterInfo
            Cluster info

        Raises
        ------
        KeyError
            If cluster not found
        """
        if cluster_id not in self._clusters:
            raise KeyError(f"Cluster {cluster_id} not found")
        return self._clusters[cluster_id]

    def list(self) -> MockClusterList:
        """
        List all clusters.

        Returns
        -------
        MockClusterList
            List of clusters
        """
        return MockClusterList(clusters=list(self._clusters.values()))

    def start(self, cluster_id: str) -> None:
        """
        Start a cluster.

        Parameters
        ----------
        cluster_id : str
            Cluster ID to start
        """
        if cluster_id in self._clusters:
            self._clusters[cluster_id].state = MockClusterState.RUNNING
            self._clusters[cluster_id].state_message = ""

    def delete(self, cluster_id: str) -> None:
        """
        Terminate (delete) a cluster.

        Parameters
        ----------
        cluster_id : str
            Cluster ID to terminate
        """
        if cluster_id in self._clusters:
            self._clusters[cluster_id].state = MockClusterState.TERMINATED
            self._clusters[cluster_id].state_message = "Terminated by user"

    def restart(self, cluster_id: str) -> None:
        """
        Restart a cluster.

        Parameters
        ----------
        cluster_id : str
            Cluster ID to restart
        """
        if cluster_id in self._clusters:
            self._clusters[cluster_id].state = MockClusterState.RESTARTING

    def set_state(self, cluster_id: str, state: str | MockClusterState) -> None:
        """
        Set cluster state directly (for testing).

        Parameters
        ----------
        cluster_id : str
            Cluster ID
        state : str or MockClusterState
            New state
        """
        if isinstance(state, str):
            state = MockClusterState(state)
        if cluster_id in self._clusters:
            self._clusters[cluster_id].state = state

    def reset(self) -> None:
        """Reset all clusters."""
        self._clusters.clear()
