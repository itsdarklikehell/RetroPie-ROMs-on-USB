# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

### How to Report

1. **Do not** open a public issue for security vulnerabilities
2. Email the maintainer at [itsdarklikehell@users.noreply.github.com](mailto:itsdarklikehell@users.noreply.github.com) with:
   - A description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes (if available)

### What to Expect

- You will receive an acknowledgment within 48 hours
- We will investigate and provide a timeline for a fix
- Once fixed, we will credit you in the release notes (unless you prefer to remain anonymous)

### Scope

This project consists of shell scripts for formatting and mounting USB drives for RetroPie. Security concerns may include:

- Improper input validation leading to formatting of wrong devices
- Privilege escalation issues
- Unsafe handling of user-provided device paths
- Command injection vulnerabilities

## Security Best Practices for Users

- Always verify the device path before running format scripts
- Run scripts as a non-root user when possible
- Review scripts before executing them
- Keep your system and RetroPie installation up to date
