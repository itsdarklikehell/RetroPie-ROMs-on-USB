# Contributing to RetroPie-ROMs-on-USB

Thank you for your interest in contributing! This project provides scripts and documentation for running RetroPie ROMs from a USB drive.

## How to Contribute

### Reporting Issues

- Check if the issue already exists before creating a new one
- Include your system details (Raspberry Pi model, OS version, RetroPie version)
- Describe the steps to reproduce the issue
- Include any error messages or logs

### Submitting Changes

1. Fork the repository
2. Create a new branch for your change (`git checkout -b feature/my-feature`)
3. Make your changes
4. Ensure your changes pass ShellCheck: `shellcheck *.sh`
5. Test your changes on a real system if possible
6. Commit with a clear, descriptive message
7. Push to your fork and open a pull request

### Code Style

- **Shell scripts**: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Always use `set -euo pipefail` at the top of scripts
- Quote all variable expansions: `"$VAR"` not `$VAR`
- Use `readonly` for constants
- Add comments explaining non-obvious logic
- Keep scripts POSIX-compatible where possible (bash is fine for this project)

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests where appropriate

## Development Setup

```bash
git clone https://github.com/itsdarklikehell/RetroPie-ROMs-on-USB.git
cd RetroPie-ROMs-on-USB

# Install shellcheck (optional but recommended)
sudo apt-get install shellcheck

# Run shellcheck on all scripts
shellcheck *.sh
```

## Testing

- Test scripts on a real Raspberry Pi with a USB drive when possible
- At minimum, verify bash syntax: `bash -n script.sh`
- Run ShellCheck and fix all warnings

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
