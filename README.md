# Odoo Project Template
## Prerequisites

- PyCharm version latest/stable 2024.2.4
- [Docker Engine for Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

## Steps to reproduce the issue
1) Open the terminal and enter the command to build Odoo: `docker compose build odoo`
![Screenshot from 2024-11-14 15-04-38.png](static/images/Screenshot%20from%202024-11-14%2015-04-38.png)
2) After the build is finished, create a new interpreter as followed:
![Screenshot from 2024-11-14 14-50-55.png](static/images/Screenshot%20from%202024-11-14%2014-50-55.png)
The docker server is just a default you get when you click "New"
3) After this, you configure the path mapping as followed:
![Screenshot from 2024-11-14 15-24-25.png](static/images/Screenshot%20from%202024-11-14%2015-24-25.png)
4) You should see that it detects the remote packages correctly here:
![Screenshot from 2024-11-14 12-14-06.png](static/images/Screenshot%20from%202024-11-14%2012-14-06.png)
5) If you now look at the External Libraries in the project, it does not detect any:
![Screenshot from 2024-11-14 15-25-38.png](static/images/Screenshot%20from%202024-11-14%2015-25-38.png)
6) An error/warning also appears regarding this in the bottom right:
![Screenshot from 2024-11-14 12-12-49.png](static/images/Screenshot%20from%202024-11-14%2012-12-49.png)