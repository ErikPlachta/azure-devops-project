"""
Mock Databricks Jobs API for local testing.

Provides a mock implementation of the Databricks SDK Jobs API,
enabling local development and testing without a live workspace.

Examples
--------
Use mock in tests::

    from mocks.jobs_mock import MockJobsAPI

    jobs = MockJobsAPI()
    run = jobs.submit(run_name="test", tasks=[...])
    result = jobs.get_run(run.run_id)
"""

from __future__ import annotations

import json
import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class MockRunLifeCycleState(str, Enum):
    """Mock run lifecycle states."""

    PENDING = "PENDING"
    RUNNING = "RUNNING"
    TERMINATED = "TERMINATED"
    SKIPPED = "SKIPPED"


class MockRunResultState(str, Enum):
    """Mock run result states."""

    SUCCESS = "SUCCESS"
    FAILED = "FAILED"
    CANCELED = "CANCELED"
    TIMEDOUT = "TIMEDOUT"


@dataclass
class MockNotebookOutput:
    """Mock notebook output."""

    result: str | None = None
    truncated: bool = False


@dataclass
class MockTaskRun:
    """Mock task run."""

    task_key: str
    notebook_output: MockNotebookOutput | None = None
    state: MockRunLifeCycleState = MockRunLifeCycleState.PENDING


@dataclass
class MockRunState:
    """Mock run state."""

    life_cycle_state: MockRunLifeCycleState = MockRunLifeCycleState.PENDING
    result_state: MockRunResultState | None = None
    state_message: str = ""


@dataclass
class MockRun:
    """Mock job run."""

    run_id: int
    run_name: str
    state: MockRunState = field(default_factory=MockRunState)
    tasks: list[MockTaskRun] = field(default_factory=list)
    run_page_url: str = ""

    def __post_init__(self) -> None:
        """Set run page URL."""
        self.run_page_url = f"https://mock.databricks.com/runs/{self.run_id}"


@dataclass
class MockSubmitResponse:
    """Mock submit response."""

    run_id: int


class MockJobsAPI:
    """
    Mock implementation of Databricks Jobs API.

    Simulates job submission and execution for testing.

    Parameters
    ----------
    auto_complete : bool
        If True, runs complete immediately. Default True.
    success : bool
        If True, runs succeed. If False, runs fail. Default True.
    result_data : dict, optional
        Data to return as notebook output.
    completion_delay_seconds : float
        Time before run completes (for async testing). Default 0.

    Examples
    --------
    Basic usage::

        jobs = MockJobsAPI()
        response = jobs.submit(run_name="test", tasks=[])
        run = jobs.get_run(response.run_id)
        assert run.state.life_cycle_state == MockRunLifeCycleState.TERMINATED
    """

    def __init__(
        self,
        auto_complete: bool = True,
        success: bool = True,
        result_data: dict[str, Any] | None = None,
        completion_delay_seconds: float = 0,
    ) -> None:
        """Initialize mock Jobs API."""
        self._runs: dict[int, MockRun] = {}
        self._next_run_id = 1
        self._auto_complete = auto_complete
        self._success = success
        self._result_data = result_data or {"status": "mock_success"}
        self._completion_delay = completion_delay_seconds
        self._run_start_times: dict[int, float] = {}

    def submit(
        self,
        run_name: str,
        tasks: list[dict[str, Any]],
        **kwargs: Any,
    ) -> MockSubmitResponse:
        """
        Submit a job run.

        Parameters
        ----------
        run_name : str
            Name for the run
        tasks : list
            Task definitions
        **kwargs
            Additional parameters (ignored)

        Returns
        -------
        MockSubmitResponse
            Response with run_id
        """
        run_id = self._next_run_id
        self._next_run_id += 1

        task_runs = [
            MockTaskRun(task_key=task.get("task_key", f"task_{i}")) for i, task in enumerate(tasks)
        ]

        run = MockRun(
            run_id=run_id,
            run_name=run_name,
            tasks=task_runs,
        )

        self._runs[run_id] = run
        self._run_start_times[run_id] = time.time()

        if self._auto_complete and self._completion_delay == 0:
            self._complete_run(run_id)

        return MockSubmitResponse(run_id=run_id)

    def get_run(self, run_id: int) -> MockRun:
        """
        Get run status.

        Parameters
        ----------
        run_id : int
            Run ID

        Returns
        -------
        MockRun
            Run object with current state

        Raises
        ------
        KeyError
            If run not found
        """
        if run_id not in self._runs:
            raise KeyError(f"Run {run_id} not found")

        run = self._runs[run_id]

        # Check if delayed completion should happen
        if (
            self._auto_complete
            and self._completion_delay > 0
            and run.state.life_cycle_state != MockRunLifeCycleState.TERMINATED
        ):
            elapsed = time.time() - self._run_start_times.get(run_id, 0)
            if elapsed >= self._completion_delay:
                self._complete_run(run_id)

        return run

    def cancel_run(self, run_id: int) -> None:
        """
        Cancel a run.

        Parameters
        ----------
        run_id : int
            Run ID to cancel
        """
        if run_id in self._runs:
            run = self._runs[run_id]
            run.state.life_cycle_state = MockRunLifeCycleState.TERMINATED
            run.state.result_state = MockRunResultState.CANCELED
            run.state.state_message = "Canceled by user"

    def _complete_run(self, run_id: int) -> None:
        """Complete a run with configured success/failure."""
        run = self._runs[run_id]
        run.state.life_cycle_state = MockRunLifeCycleState.TERMINATED

        if self._success:
            run.state.result_state = MockRunResultState.SUCCESS
            run.state.state_message = "Run completed successfully"

            # Set notebook output only if not already set via set_result
            if run.tasks and run.tasks[0].notebook_output is None:
                run.tasks[0].notebook_output = MockNotebookOutput(
                    result=json.dumps(self._result_data)
                )
        else:
            run.state.result_state = MockRunResultState.FAILED
            run.state.state_message = "Mock failure"

    def set_result(self, run_id: int, data: dict[str, Any]) -> None:
        """
        Set the result data for a run.

        Parameters
        ----------
        run_id : int
            Run ID
        data : dict
            Result data to return
        """
        if run_id in self._runs:
            run = self._runs[run_id]
            if run.tasks:
                run.tasks[0].notebook_output = MockNotebookOutput(result=json.dumps(data))

    def reset(self) -> None:
        """Reset all runs and state."""
        self._runs.clear()
        self._run_start_times.clear()
        self._next_run_id = 1
