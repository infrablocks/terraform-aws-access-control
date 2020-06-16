## 1.0.0 (June 16th, 2020)

BACKWARDS INCOMPATIBILITIES / NOTES:

* Switch from `count` and array based indexing of users and groups to `for_each`
  and map key based indexing. This makes it easier to remove users without
  re-provisioning other users based on the array indexing changing and is less
  error-prone in terms of misindexing. Running this after an upgrade will 
  result in all users and groups being recreated.
