# containerfy

## Makefile Targets

### `fix-permissions`

Sets .dockermount group ownership to 'staff'

> [!NOTE]
> If cloned into a folder owned by `wheel` (unix-based systems e.g. Darwin/MacOS), run `make fix-permission` to **set .dockermount group ownership to 'staff'**.
