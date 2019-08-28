#!/usr/bin/env python3
#
# Copyright 2019 Copyright (c) 2019 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import util
import os
import sys
import subprocess
import version
import yaml
import ctx
from product.util import (
    ComponentDescriptor,
    ComponentDescriptorResolver,
)
from gitutil import (
    GitHelper
)
from github.util import (
    GitHubRepositoryHelper,
)

it_label = "test/integration"
source_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../")


config_dir = os.getenv("OUT_PATH")
if not config_dir:
    config_dir = source_path

config_path = os.path.join(config_dir, "config.yaml")


repo_owner_name=os.getenv("SOURCE_GITHUB_REPO_OWNER_AND_NAME")
github_repository_owner,github_repository_name = repo_owner_name.split("/")


cfg_set = ctx.cfg_factory().cfg_set(os.getenv("CONCOURSE_CURRENT_CFG"))
github_cfg = cfg_set.github()

git_helper = GitHelper(
    repo=os.path.join(source_path, ".git"),
    github_cfg=github_cfg,
    github_repo_path=repo_owner_name
)
github_helper = GitHubRepositoryHelper(
        owner=github_repository_owner,
        name=github_repository_name,
        github_cfg=github_cfg,
    )

pull_request_number=git_helper.pr_id()
labels = [str(label) for label in github_helper.repository.pull_request(pull_request_number).issue().labels()]

print("Found labels {}".format(labels))

if it_label not in labels:
    print("{} is not set".format(it_label))
    exit(1)


print("generate config file")
labels.remove(it_label)
config_file_data = {
    "labels": [ label for label in labels if label.startswith("platform/") ]
}

# determine base cluster
print("determine base cluster")
base_cluster = [label for label in labels if label.startswith("base/")]
if base_cluster:
    config_file_data["baseCluster"] = base_cluster[0].replace("base/", "")

raw_config = yaml.dump(config_file_data)

with open(config_path, "w+") as file:
    file.write(raw_config)

print("Config file written to {}".format(config_path))
print(raw_config)