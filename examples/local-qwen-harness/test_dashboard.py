#!/usr/bin/env python3
import unittest
import sys
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).parent))
import dashboard


class DashboardTests(unittest.TestCase):
    @patch.object(dashboard, "container_state")
    def test_active_recipe(self, state):
        state.side_effect = lambda name: "running" if name == "qwen38-full" else "exited"
        self.assertEqual(dashboard.active_qwen(), ("exl3", "qwen38-full", "running"))

    @patch.object(dashboard, "command", return_value="1024, 32768, 80, 65, 400.5, 575.0")
    def test_gpu_metrics(self, _command):
        metrics = dashboard.gpu_metrics()
        self.assertEqual(metrics[0], ("VRAM", "1,024 / 32,768 MiB"))
        self.assertEqual(metrics[-1], ("Power", "400 / 575 W"))

    @patch.object(dashboard, "command", return_value="model ready")
    @patch.object(dashboard, "active_qwen", return_value=("ninfer", "qwen38-ninfer", "running"))
    def test_qwen_log_source(self, _active, command):
        self.assertIn("model ready", dashboard.logs_for(1))
        command.assert_called_once_with(["docker", "logs", "--tail", "200", "qwen38-ninfer"])

    def test_terminal_cleanup(self):
        self.assertEqual(dashboard.clean("\x1b[31mred\x1b[0m\ttext"), "red    text")

    def test_grid_columns(self):
        row = dashboard.grid_row("one", "two", "three", "four")
        self.assertEqual([row.index(value) for value in ("one", "two", "three", "four")], [2, 20, 36, 60])


if __name__ == "__main__":
    unittest.main()
