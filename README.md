# containerfy

## Clone into existing folder (e.g. `/Users/Shared/Tools/containerfy`)

```bash
git init
git branch -m main
git remote add origin https://github.com/stairwaytowonderland/containerfy.git
git fetch
# Run the following two commands if a managed file has uncommitted changes or differs from HEAD
#git branch main origin/main
#git reset HEAD -- .
git pull origin main
git branch --set-upstream-to=origin/main main
```

## Makefile Targets

### `fix-permissions`

Fixes .dockermount permissions for multiple users

> [!NOTE]
> If cloned into a folder owned by `wheel` (unix-based systems e.g. Darwin/MacOS), run `make fix-permission` if receiving permissions-related error when trying to run as multiple users.
