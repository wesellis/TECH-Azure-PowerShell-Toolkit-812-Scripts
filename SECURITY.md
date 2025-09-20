# Security Policy

## Supported Versions

We provide security updates for the following versions of the Azure Enterprise PowerShell Toolkit:

| Version | Supported          |
| ------- | ------------------ |
| 3.0.x   | Yes               |
| 2.x.x   | Yes               |
| < 2.0   | No                |

## Reporting a Vulnerability

The Azure Enterprise PowerShell Toolkit team takes security vulnerabilities seriously. We appreciate your efforts to responsibly disclose your findings.

### How to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to:

- **Primary Contact**: wes@wesellis.com
- **Subject**: [SECURITY] Azure PowerShell Toolkit Vulnerability

### What to Include

Please include the following information in your report:

- Description of the vulnerability
- Steps to reproduce the issue
- Affected versions
- Potential impact
- Any suggested fixes or mitigations

### Response Timeline

- **Acknowledgment**: We will acknowledge receipt of your vulnerability report within 48 hours
- **Initial Assessment**: We will provide an initial assessment within 5 business days
- **Updates**: We will keep you informed of our progress throughout the investigation
- **Resolution**: We aim to resolve critical vulnerabilities within 30 days

### Disclosure Policy

- We request that you do not publicly disclose the vulnerability until we have had a chance to investigate and address it
- Once a fix is available, we will coordinate the disclosure timeline with you
- We will credit you in our security advisory (unless you prefer to remain anonymous)

## Security Best Practices

When using the Azure Enterprise PowerShell Toolkit:

### For Users

1. **Keep Scripts Updated**: Always use the latest version of scripts
2. **Review Before Execution**: Understand what a script does before running it
3. **Secure Credentials**: Never hardcode credentials in scripts
4. **Use Secure Methods**: Utilize Azure Key Vault, Managed Identities, or secure credential storage
5. **Principle of Least Privilege**: Run scripts with minimal required permissions
6. **Audit Logging**: Enable logging for all script executions in production

### For Contributors

1. **No Hardcoded Secrets**: Never commit credentials, API keys, or secrets
2. **Input Validation**: Always validate user inputs and parameters
3. **Error Handling**: Implement proper error handling to prevent information disclosure
4. **Secure Defaults**: Use secure default configurations
5. **Dependencies**: Keep dependencies updated and scan for vulnerabilities

## Security Features

The repository includes several security measures:

### Automated Security Scanning

- **Secrets Detection**: GitLeaks scans for accidentally committed secrets
- **Dependency Scanning**: Regular checks for vulnerable dependencies
- **Code Analysis**: Static analysis for security anti-patterns

### Secure Coding Standards

- **PSScriptAnalyzer**: Enforces secure PowerShell coding practices
- **Code Review**: All changes require review before merging
- **Testing**: Comprehensive testing including security test cases

### Access Controls

- **Branch Protection**: Main branch requires reviews and status checks
- **Signed Commits**: Contributors are encouraged to sign commits
- **Release Management**: Controlled release process with security validation

## Known Security Considerations

### Azure Authentication

- Scripts use Azure PowerShell modules for authentication
- Supports Azure AD, Service Principals, and Managed Identities
- No credentials are stored in the repository

### Permissions

- Scripts require appropriate Azure RBAC permissions
- Follow principle of least privilege
- Document required permissions in script headers

### Data Handling

- Scripts may process sensitive Azure configuration data
- No data is transmitted outside Azure environments
- Local temporary files are cleaned up appropriately

## Security Updates

Security updates will be:

- Documented in the CHANGELOG.md
- Tagged with appropriate version bumps
- Announced through GitHub releases
- Communicated via security advisories when applicable

## Contact

For general security questions or concerns:

- Email: wes@wesellis.com
- Create a GitHub issue (for non-sensitive topics only)

For urgent security matters, please use the vulnerability reporting process described above.

---

**Last Updated**: September 19, 2025
**Security Policy Version**: 1.0