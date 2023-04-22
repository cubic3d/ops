#!/usr/bin/python

# Copyright: Waldemar Faist <cubic@coldice.net>
# GNU General Public License v3.0+ (see https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function

__metaclass__ = type

DOCUMENTATION = r"""
module: vyconf
short_description: Manages and synchronizes VyOS config to remote device by keeping idempotency
description:
    - This module synchronizes a local config written in C(set) syntax with a remote device.
    - It determines a plan by comparing a local config with the current running on the device.
    - The plan is converted into a operational commands that are executed remotely.
version_added: "2.14"
author: Waldemar Faist (@cubic3d)
options:
    config:
        description: Config as a string consisting of C(set) commands separated by newlines.
        required: true
        type: str
    save:
        description: Execute a save command to persist the config after reboots.
        default: false
        type: bool
notes:
    - Check mode does not commit or save operations determined by this module.
    - The existing can be exported using C(show configuration commands) and used as an input.
"""

EXAMPLES = r"""
- name: Apply config
  vyconf:
    config: "{{ lookup('template', 'config/main.j2') }}"
    save: yes
"""

RETURN = r"""
plan:
    description: Categorised diff between local and remote configuration.
    returned: success
    type: dict
    contains:
        add:
            description: Lines that have been added compared to remote state.
            returned: success
            type: list
            elements: str
        delete:
            description: Lines that have been deleted compared to remote state.
            returned: success
            type: list
            elements: str
        unchanged:
            description: Lines that have not been changed compared to remote state.
            returned: success
            type: list
            elements: str
operations:
    description: Determined commands needed to execute the plan.
    returned: success
    type: list
    elements: str
operations_result:
    description: Stdout of execution of operations.
    returned: success
    type: list
    elements: str
"""

from ansible.module_utils.basic import AnsibleModule
from bisect import bisect_right
from shlex import split


def run_commands(commands: list[str]) -> list[str]:
    command_str = "\n".join(commands)

    r = module.run_command(
        "/bin/vbash",
        data=f"source /opt/vyatta/etc/functions/script-template\n{command_str}\nexit\n",
    )

    if r[0] != 0 or r[2] != "":
        module.fail_json(msg=r[2], **{"code": r[0]})

    return [line for line in r[1].split("\n") if line]


def parse_config_file(config: str) -> list[str]:
    config_lines = []

    for line in config.splitlines():
        command = line.strip()
        if command == "" or not command.startswith("set "):
            continue
        config_lines.append(command)

    return config_lines


def create_plan(
    config_new: list[str], config_current: list[str]
) -> dict[str, list[str]]:
    current_set = set(config_current)
    new_set = set(config_new)

    if len(current_set) != len(config_current) or len(new_set) != len(config_new):
        module.fail_json(msg="duplicate config lines found in new or current config")

    add = []
    delete = []
    unchanged = []

    for i, l in enumerate(config_new):
        if l in current_set:
            unchanged.append(config_new[i])
        else:
            add.append(config_new[i])

    for i, l in enumerate(config_current):
        if l not in new_set:
            delete.append(config_current[i])

    return {"add": add, "delete": delete, "unchanged": unchanged}


def create_operations(plan: dict[str, list[str]]) -> list[str]:
    delete_operations = set()
    unchanged_sorted = sorted(plan["unchanged"])

    for d in plan["delete"]:
        position = bisect_right(unchanged_sorted, d)
        candidates = []

        try:
            candidates.append(split(unchanged_sorted[position])[1:])
        except IndexError:
            pass
        try:
            candidates.append(split(unchanged_sorted[position - 1])[1:])
        except IndexError:
            pass

        deleted = split(d)[1:]

        longest_prefix_count = 0
        for candidate in candidates:
            count = 0
            for a, b in zip(candidate, deleted):
                if a != b:
                    break
                count += 1

            if count > longest_prefix_count:
                longest_prefix_count = count

        delete_command = "delete " + " ".join(deleted[: longest_prefix_count + 1])
        delete_operations.add(delete_command)

    return list(delete_operations) + plan["add"]


def run_operations(operations: list[str]) -> list[str]:
    commands = operations.copy()

    if not module.check_mode:
        commands.append("commit comment 'commited by VyConf Ansible module'")
        if module.params["save"]:
            commands.append("save")

    return run_commands(commands)


def run_module():
    module_args = dict(
        config=dict(type="str", required=True), save=dict(type="bool", default=False)
    )

    result = dict()

    global module
    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    config_new = parse_config_file(module.params["config"])
    config_current = run_commands(["run show configuration commands"])

    result["plan"] = create_plan(config_new, config_current)
    result["operations"] = create_operations(result["plan"])

    if len(result["operations"]):
        result["changed"] = True
        result["operations_result"] = run_operations(result["operations"])

    module.exit_json(**result)


def main():
    run_module()


if __name__ == "__main__":
    main()
