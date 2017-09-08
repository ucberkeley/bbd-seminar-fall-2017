% BBD Seminar Week 2: Overview of tools and resources on campus and beyond: Savio, Box/bDrive, XSEDE, cloud resources
% September 11, 2017
% Chris Paciorek and Deb McCaffrey (BRC)

# Introduction

The goal this week is to familiarize you with various resources and tools for computation and data storage available for researchers on campus and at the national level.

Two key take-home messages:

 - if you feel like you're scaling back the questions you can answer because of computational limits, talk to us about larger-scale resources that may be available
 - consultants with Berkeley Research Computing and Research Data Management are here to help (XSEDE also has extensive consulting support)


The materials for this session are available using git at [https://github.com/ucberkeley/bbd-seminar-fall-2017](https://github.com/ucberkeley/bbd-seminar-fall-2017) or simply as a [zip file](https://github.com/ucberkeley/bbd-seminar-fall-2017/archive/master.zip). The HTML is also on bCourses.

# Outline

This training session will cover the following topics:

 - Overview of resources
     - Data storage
     - Data transfer
     - Computation
 - Cloud-based virtual machines (VMs)
     - Google cloud platform example
     - AWS services
 - XSEDE (NSF's national computing infrastructure)
     - Overview
     - What is possible on XSEDE
     - Key XSEDE resources and what they're good for
     - Example usage of Jetstream (starting up a VM)
     - Getting an account
 - Containerization and portable computation
     - Overview of containers
     - Docker
     - Singularity      
 - Where to get more help


# Data storage for large datasets

 - Box and Google Drive (i.e., bDrive) provide unlimited file storage
 - Savio scratch drive provides extensive short-term storage
 - [Savio condo storage service](http://research-it.berkeley.edu/services/high-performance-computing/brc-condo-storage-service-savio) provides inexpensive long-term storage
 - AWS and other cloud services have paid offerings

# Data storage and computation for confidential data

 - UC Berkeley IST can set up secure virtual machines (VMs)
 - no vetted solution using commercial cloud providers yet
 - ongoing discussions about providing for secure data on Savio
 - BRC has a Windows-based virtual machine service, AEoD, that may be able to address secure data issue

Research Data Management can help you explore options.

# Data transfer: Globus

You can use Globus Connect to transfer data data to/from Savio (and between other resources) quickly and unattended. This is a better choice for large transfers. Here are some [instructions](http://research-it.berkeley.edu/services/high-performance-computing/using-globus-connect-savio).

Globus transfers data between *endpoints*. Possible endpoints include: Savio, your laptop or desktop, NERSC, and XSEDE, among others.

Savio's endpoint is named `ucb#brc`.

If you are transferring to/from your laptop, you'll need 1) Globus Connect Personal set up, 2) your machine established as an endpoint and 3) Globus Connect Pesonal actively running on your machine. At that point you can proceed as below.

To transfer files, you open Globus at [globus.org](https://globus.org) and authenticate to the endpoints you want to transfer between. You can then start a transfer and it will proceed in the background, including restarting if interrupted. 

Globus also provides a [command line interface](https://docs.globus.org/cli/using-the-cli) that will allow you to do transfers programmatically, such that a transfer could be embedded in a workflow script.


# Data transfer: Box 

Box provides **unlimited**, free, secured, and encrypted content storage of files with a maximum file size of 15 Gb to Berkeley affiliates. So it's a good option for backup and long-term storage. 

You can move files between Box and your laptop using the Box Sync app. And you can interact with Box via a web browser at [http://box.berkeley.edu](http://box.berkeley.edu).

The best way to move files between Box and Savio is [via lftp as discussed here](http://research-it.berkeley.edu/services/high-performance-computing/transferring-data-between-savio-and-your-uc-berkeley-box-account). This allows you to programmatically transfer data from the command line. 

Similar functionality may be possible to transfer data between Box and XSED or Box and cloud-based services.

BRC is working (long-term) on making Globus available for transfer to/from Box, but it's not available yet.

# Data transfer: bDrive (Google Drive)

bDrive provides **unlimited**, free, secured, and encrypted content storage of files with a maximum file size of 5 Tb to Berkeley affiliates.

You can move files to and from your laptop using the Google Drive app.

You can move files between bDrive and Savio [via the Google Drive app as discussed here](http://research-it.berkeley.edu/services/high-performance-computing/transferring-data-between-savio-and-your-bdrive-google-drive).

# Cloud computing overview

Various cloud providers (AWS, Google Compute Platform, Microsoft Azure) provide a wide variety of resources and tools through the cloud.

 - virtual machines
 - virtual clusters for distributed computing
 - deep learning platforms
 - Spark/Hadoop big data platforms
 - services for running SQL queries on big datasets
 - cloud storage

Note that Savio and XSEDE provide many of these for free.

Berkeley Research Computing consultants can discuss options with you.

# Google cloud platform overview

We'll walk through how one sets up a virtual machine (VM) through Google in seminar.

You can sign up for a free trial with $300 in credits for the next year at cloud.google.com. As far as I can tell you can actually do this under more than one google account, and you can decide whether to do with an @gmail.com account or an @berkeley.edu bConnected account. You'll need to give a credit card but won't have to pay anything unless you explicitly ok it at some later time.

You'll need to create a new project before you can do anything.

Once you sign on and have a project, you'll be at the Console from which you can control your various interactions. E.g., you could start up VMs, control who has access to your account and projects, start up big data services, etc.

# Google cloud platform VM demo

 - https://cloud.google.com
 - console
 - create a project and open it
 - compute engine -> VM instances
 - (note REST and gcloud commandline startup notes at bottom)
 - SSH (3 options)
    - ssh in browser
    - gcloud compute --project "bbd-demo" ssh --zone "us-west1-a" "instance-1" (but do "gcloud auth login" first)
    - set up ssh key pair and use usual ssh
 - install software
 - run computations

# XSEDE resources overview

Some core resources we tend to refer researchers to:

- Bridges
    - traditional HPC
    - Hadoop/Spark
    - large memory (up to 12 TB/node)
    - GPU nodes
    - web server nodes
- Comet
    - less traditional HPC
    - Singularity
    - GPU nodes
    - Science Gateways
-Jetstream
    - VM-based cloud resource
    - long running jobs/servers
    - *possibly* can be used for secure data/compute

Some additional resources:

- Stampede2
    - Intel Many Integrated Core architecture machine
    - KNL nodes with SKX to come
- XStreme
    - GPU only machine
- Wrangler
    - data storage machine
    - persistent databases
    - Hadoop


# XSEDE startup allocation example

See Google doc.

Thanks to Chris Kennedy for sharing this.

# Overview of containers

Containers are like lightweight virtual machines. A virtual machine is a disposable computer that runs on your actual computer or somebody else's computer.

You have control over the operating system (what variant of Linux) and  what gets installed in the container. 

Containers are built off of 'images' that hold the software installed on the image. A 'container' or an 'instance' is the running version of that image. You can run multiple containers based on the same image.

You can use other people's images or create your own image, often building off an existing image. 

# Docker

You can use Docker to run other people's existing "images" (i.e., virtual machines).

Here we might run a basic Ubuntu 16.04 Linux container or a Linux container with a bunch of R-related things installed.

```
docker run -it ubuntu:16.04 /bin/bash
docker run -it ubuntu:16.04 cat /proc/cpuinfo
docker run -it rocker/r-base /bin/bash
docker run -it rocker/r-base Rscript -e "library(ggplot2)"
```

`docker run` runs a container based on the image selected - it's like choosing a computer with particular software and then starting it up to use it.

 You can run the Docker container either interactively or executing a particular script in the background to carry out your computational job.

Or if you need to install particular software, you can create a Docker image that you set up so it has the software you need installed on it. You can choose whatever Linux variant you are comfortable with and/or it's easy to install the software on.

You do this by creating a `Dockerfile` (or modifying somebody else's). Here's a very basic Dockerfile that would install Python.

```
# source https://github.com/mingfang/docker-geekbench
FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y \
    python \
    python-setuptools \
    python-pip


# add additional installation commands here using standard shell code
```

See also `Dockerfile-R` to see how one could create an image with R and related software on it.

You can run a Docker container on your own machine (including Windows, Mac), Google cloud platform, AWS EC2, XSEDE Jetstream.

# Singularity

You can't run Docker on most clusters (e.g., Savio, most XSEDE resources) because Docker requires administrative (root) privileges.

Some resources (Savio, XSEDE's Comet) allow you to run Singularity containers, which are similar to Docker containers but don't have root access and therefore are more acceptable to cluster administrators.

You can easily convert your Docker container to a Singularity container.

(
Side note, here's what the command looks like:
```
docker run  -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/image:/output  --privileged -t --rm  singularityware/docker2singularity name_of_docker_image
```
)

Then just run it on the cluster of interest and you won't have to worry about how to install software on that cluster; the software is already installed in your container.

# Upcoming events

 - September 15 and every two weeks thereafter: [Cloud working group](http://research-it.berkeley.edu/services/cloud-computing-support/cloud-working-group) sessions on various topics in using the cloud.
 - September 19: Introduction to Savio training: largely duplicates the Sep. 18 BBD seminar, but with more detail. Register here: https://goo.gl/forms/eAn1BeO1fFdbKeZE2 

# How to get additional help

 - For questions about computing resources in general, including cloud computing and XSEDE: 
    - brc@berkeley.edu
 - For questions about data management (including HIPAA-protected data): 
    - researchdata@berkeley.edu
 - Or email me (paciorek@berkeley.edu) directly -- part of my role with the seminar and BBD grant is to provide computing support.



