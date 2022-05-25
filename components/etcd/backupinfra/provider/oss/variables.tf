// Copyright 2019 Copyright (c) 2019 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file.
//
# Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

variable "ACCESS_KEY" {
  description = "ALICLOUD Access Key"
  type        = string
}

variable "SECRET_KEY" {
  description = "ALICLOUD Secret Key"
  type        = string
}

variable "REGION" {
  description = "Region of the ALICLOUD bucket"
  type        = string
}

variable "BUCKETNAME" {
  description = "Name of the bucket"
  type        = string
}

variable "LANDSCAPE" {
  description = "Name of the Landscape (for tagging)"
  type        = string
}

