## 3.0.0 (Dec 28th, 2022)

BACKWARDS INCOMPATIBILITIES / NOTES:

* This module is now compatible with Terraform 1.0 and higher.

## 2.0.0 (May 27th, 2021)

BACKWARDS INCOMPATIBILITIES / NOTES:

* This module is now compatible with Terraform 0.14 and higher.

## 1.0.0 (June 16th, 2020)

BACKWARDS INCOMPATIBILITIES / NOTES:

* Switch from `count` and array based indexing of users and groups to `for_each`
  and map key based indexing. This makes it easier to remove users without
  re-provisioning other users based on the array indexing changing and is less
  error-prone in terms of misindexing. Running this after an upgrade will 
  result in all users and groups being recreated.
