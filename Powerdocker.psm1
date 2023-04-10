
function Get-DockerContainer {
    <#
    .SYNOPSIS
        Retrieves information about Docker containers running on the local system.
    .DESCRIPTION
        This function retrieves detailed information about Docker containers running on the local system.
        It uses the docker command-line tool to retrieve container IDs, and then uses docker inspect
        to get detailed information about each container. The function returns an object with the following
        properties for each container:

        - Name: The name of the container, with the forward slash (/) removed.
        - Image: The name of the Docker image used to create the container.
        - Status: The status of the container, such as running or stopped.
        - IPAddress: The IP address of the container.
        - ID: The unique ID of the container.
        - Volumes: An array of objects describing the volumes attached to the container. Each object
        has a Source and Destination property.
        - Dockercomposefile: The path to the Docker Compose file used to create the container, if applicable.
        - Dockercomposefolder: The path to the working directory used by the Docker Compose file, if applicable.

    .PARAMETER Name
        The name of the container to retrieve information for. If this parameter is not specified,
        information for all containers on the system is retrieved.
    .INPUTS
        None
    .OUTPUTS
        Returns an object with detailed information about the Docker containers running on the local system.
    .NOTES
        This function requires the Docker command-line tool to be installed and available in the system PATH.
        Docker must also be running on the local system.
    #>


    param (
        [String]
        $Name
    )

    $Container = docker ps -a --format '{"ID":"{{ .ID }}"}' | ConvertFrom-Json | ForEach-Object { docker inspect $_.id | ConvertFrom-Json }

    if ($Name) {
        $Container = $Container | Where-Object { $_.Name -like "*$Name*" }
    }

    $Container | ForEach-Object { [PSCustomObject]@{
            Name                = ($_.Name).replace("/", "")
            Image               = $_.config.Image
            Status              = $_.state.status
            IPAddress           = $_.networksettings.networks.psobject.members | Where-Object { $_.Name -ne "ToString" -and $_.Name -ne "GetType" -and $_.Name -ne "Equals" -and $_.Name -ne "GetHashCode" } | ForEach-Object { $_.Value.IPAddress }
            ID                  = $_.id
            Volumes             = $_.mounts | Select-Object source, destination
            Dockercomposefile   = $_.config.labels."com.docker.compose.project.config_files"
            Dockercomposefolder = $_.config.labels."com.docker.compose.project.working_dir"
        }
    } | Sort-Object Name
}

function Remove-DockerContainer {
    <#
    .SYNOPSIS
        Removes a Docker container with the specified name.
    .DESCRIPTION
        This function removes a Docker container with the specified name. By default, the container will be stopped and then removed. Use the -Force parameter to force the removal of a running container.
    .PARAMETER Name
        The name of the Docker container to remove.
    .PARAMETER Force
        Indicates that a running container should be forcibly removed.
    .EXAMPLE
        PS C:\> Remove-DockerContainer -Name MyContainer
        This example removes the Docker container named "MyContainer".
    .EXAMPLE
        PS C:\> Remove-DockerContainer -Name MyContainer -Force
        This example forcibly removes the Docker container named "MyContainer" even if it is running.
    .NOTES
        This function requires the Docker command-line interface (CLI) to be installed on the local machine.
    #>
    param (
        # Name of the Dockercontainer
        [Parameter(Mandatory)]
        [String]
        $Name,
        [Switch]
        $Force
    )

    begin {

    }

    process {
        if ($Force) {
            docker rm -f $Name
        }
        else {
            docker rm $Name
        }
    }
    end {}
}
