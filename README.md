# AzureIaC

## Overview

Welcome to the AzureIaC repository! This repository contains Infrastructure as Code (IaC) scripts and configurations to provision and manage Azure resources using Terraform and Ansible. The goal is to automate and simplify the deployment and management of Azure infrastructure.

## Contents

- `terraform/`: Terraform configurations for provisioning Azure infrastructure.
- `ansible/`: Ansible playbooks for configuration management and deployment automation.
- `scripts/`: PowerShell scripts for managing Windows updates and reboots.
- `Servers.txt`: List of servers for update management.
- `UpdateLog.txt`: Log file for Windows update records.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) installed on your local machine.
- [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell) installed on your local machine.
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed on your local machine.
- Access to an Azure account with sufficient permissions to create and manage resources.
- Properly configured SSH keys for accessing remote servers.

## Terraform Setup

1. **Authenticate with Azure**:

    ```sh
    az login
    ```

2. **Initialize Terraform**:

    ```sh
    cd terraform
    terraform init
    ```

3. **Plan Infrastructure Changes**:

    ```sh
    terraform plan
    ```

4. **Apply Infrastructure Changes**:

    ```sh
    terraform apply
    ```

## Ansible Setup

1. **Install Ansible Collections and Roles**:

    ```sh
    ansible-galaxy install -r ansible/requirements.yml
    ```

2. **Run Ansible Playbooks**:

    ```sh
    ansible-playbook -i ansible/inventory ansible/playbook.yml
    ```

## PowerShell Scripts for Windows Updates

### Prerequisites

- Ensure WinRM is enabled and properly configured on all target servers:

    ```powershell
    Enable-PSRemoting -Force
    ```

- Add the list of servers to `Servers.txt`.

### Usage

1. **Run the Windows Update and Restart Script**:

    ```powershell
    .\scripts\UpdateAndRestartServers.ps1
    ```

2. **Check the Update Log**:

    Review `UpdateLog.txt` for details on installed updates and server reboots.

## Configuration

### Terraform

- Adjust configurations in the `terraform/` directory according to your infrastructure requirements.

### Ansible

- Modify Ansible playbooks and inventory files in the `ansible/` directory to suit your environment.

### PowerShell

- Customize `scripts/UpdateAndRestartServers.ps1` to match your update and logging needs.

## Contributing

We welcome contributions to improve our IaC setup and automation scripts. Please fork the repository and submit a pull request with your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions or support, please contact [your_email@example.com].

