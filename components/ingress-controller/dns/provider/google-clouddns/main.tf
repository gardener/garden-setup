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

provider "google" {
  credentials = "${var.SERVICEACCOUNT}"
  project = "${var.PROJECT}"
}

//=====================================================================
//= CloudDNS Record
//=====================================================================

resource "google_dns_record_set" "gardener-ingress" {
  managed_zone = "${var.HOSTED_ZONE_ID}"
  name         = "${var.DNS_NAME}."
  type         = "${var.RECORD_TYPE}"
  ttl          = 120
  rrdatas      = ["${var.RECORD_VALUE}"]
}
