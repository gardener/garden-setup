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
import version
import yaml
import ctx
from product.util import (
    ComponentDescriptor,
    ComponentDescriptorResolver,
)
from github.util import (
    GitHubRepositoryHelper,
)

it_label = "test/integration"
labels_dir = os.getenv("OUT_PATH")
if not labels_dir:
    labels_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../")

labels_path = os.path.join(labels_dir, "labels.yaml")

pull_request_number=sys.argv[1]

repo_owner=os.getenv("SOURCE_GITHUB_REPO_OWNER_AND_NAME")
github_repository_owner,github_repository_name = repo_owner.split("/")


cfg_set = ctx.cfg_factory().cfg_set(os.getenv("CONCOURSE_CURRENT_CFG"))
github_cfg = cfg_set.github()

github_helper = GitHubRepositoryHelper(
        owner=github_repository_owner,
        name=github_repository_name,
        github_cfg=github_cfg,
    )

pull_request = github_helper.repository.pull_request(pull_request_number)
short_labels = list(pull_request.issue().labels())
labels = [str(label) for label in short_labels]

print("Found labels {}".format(labels))

if it_label not in labels:
    print("{} is not set".format(it_label))
    exit(1)


print("generate labels file")
labels.remove(it_label)
labels_file_data = {
    "labels": labels
}

raw_labels = yaml.dump(labels_file_data)

with open(labels_path, "w+") as file:
    file.write(raw_labels)

print("Lables file written to {}".format(labels_path))
print(raw_labels)

