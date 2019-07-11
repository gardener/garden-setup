// Copyright 2019 Copyright (c) 2019 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file.
//
// Licensed under the Apache License, Version 2.0 (the "License");
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

provider "openstack" {
  user_name        = "${var.USERNAME}"
  password         = "${var.PASSWORD}"
  tenant_name      = "${var.TENANT_NAME}"
  region           = "${var.REGION}"
  auth_url         = "${var.AUTH_URL}"
  domain_name      = "${var.DOMAIN_NAME}"
  user_domain_name = "${var.USER_DOMAIN_NAME}"
}


//=====================================================================
//= GCS bucket
//=====================================================================

resource "openstack_objectstorage_container_v1" "bucket" {
  name          = "${var.BUCKETNAME}"
  region        = "${var.REGION}"
  force_destroy = true
}

//=====================================================================
//= Output variables
//=====================================================================

output "bucketName" {
  value = "${openstack_objectstorage_container_v1.bucket.name}"
}
