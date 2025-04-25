CREATE DATABASE IF NOT EXISTS `kc_authn_01_db`;
CREATE USER IF NOT EXISTS 'kc_authn_u01'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON `kc_authn_01_db`.* TO 'kc_authn_u01'@'%';

-- dev root access from host to VM, e.g. using Workbench
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;
