FROM openwhisk/dockerskeleton
RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
RUN ibmcloud plugin install schematics
ENV FLASK_PROXY_PORT 8080
ADD exec /action/exec
RUN chmod +x /action/exec
CMD ["/bin/bash", "-c", "cd actionProxy && python -u actionproxy.py"]
