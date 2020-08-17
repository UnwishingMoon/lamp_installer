# lamp_installer
Automatic LAMP installer for Debian/Ubuntu based distribution

It will install these services:
- Apache2
- Mysql
- PHP
- PHPMyAdmin

It will also secure Mysql ready for production

```
Usage: filename DBRootPassword PHPMyAdminUserPassword
```
- **filename** is the name of the file to be executed
- **DBRootPassword** is the Root password of the database
- **PHPMyAdminUserPassword** is the password for the phpmyadmin user