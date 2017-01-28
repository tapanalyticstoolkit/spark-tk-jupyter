FROM clearlinux


# Install required bundles
RUN swupd bundle-add \
    editors \
    java-basic \
    python-basic \
    python-basic-dev \
    python-extras \
    machine-learning-basic 


# this is due to the corrupt pexpect installed
RUN pip2.7 install -I pexpect


# install some required modules for running Jupyter notebooks
RUN pip2.7 install \
    runipy \
    notebook \
    tabulate==0.7.5 \
    snakebite==2.11.0 \
    ordereddict \
    jupyter-spark \
    futures \
    awscli


# Copy misc modules for TAP to python2.7 site-packages
COPY misc-modules/* $CONDA_DIR/lib/python2.7/site-packages/


# Install Tini
ENV TINI_VERSION="v0.13.2"
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/
RUN chmod +x /usr/bin/tini


# Download and Install Spark
ENV APACHE_SPARK_VERSION "1.6.0"
ENV SPARK_HOME "/usr/local/spark-$APACHE_SPARK_VERSION-bin-hadoop2.6"
ENV PATH "$SPARK_HOME/bin:$PATH"
ENV SPARK_CONF_DIR "/etc/spark/conf"
ENV HADOOP_CONF_DIR "/etc/hadoop/conf"
ENV YARN_CONF_DIR "$HADOOP_CONF_DIR"
ENV PYSPARK_PYTHON "python2.7"
ENV PYTHONPATH "/usr/local/spark-$APACHE_SPARK_VERSION-bin-hadoop2.6/python:/usr/local/spark-$APACHE_SPARK_VERSION-bin-hadoop2.6/lib/py4j-0.9-src.zip:$PYTHONPATH"
ADD http://archive.apache.org/dist/spark/spark-$APACHE_SPARK_VERSION/spark-$APACHE_SPARK_VERSION-bin-hadoop2.6.tgz /usr/local
RUN \ 
    tar xzf /usr/local/spark-$APACHE_SPARK_VERSION-bin-hadoop2.6.tgz -C /usr/local && \
    rm -rf /usr/local/spark-$APACHE_SPARK_VERSION-bin-hadoop2.6.tgz && \
    mkdir -p $SPARK_CONF_DIR $HADOOP_CONF_DIR


# Cloudera config is expecting a classpath.txt, also fix some permissions
RUN ls $SPARK_HOME/lib/* > $SPARK_CONF_DIR/classpath.txt && \
    mkdir -p /user/spark/applicationHistory && \
    chown -R $NB_USER:users /user/spark


# Set required paths for spark-tk/daal-tk packages
ENV SPARKTK_HOME "/usr/local/sparktk-core"
ENV DAALTK_HOME "/usr/local/daaltk-core"
ENV LD_LIBRARY_PATH "/usr/local/daal-2016.2.181:$LD_LIBRARY_PATH"
ARG TKLIBS_INSTALLER_URL="https://github.com/trustedanalytics/daal-tk/releases/download/v0.7.4/daal-install"
ARG TKLIBS_INSTALLER="daal-install"


# Install spark-tk/daal-tk packages
ADD $TKLIBS_INSTALLER_URL /usr/local/
RUN cd /usr/local && \ 
    chmod +x $TKLIBS_INSTALLER  && \
    sync && \
    ./$TKLIBS_INSTALLER && \
    ln -s /usr/local/sparktk-core-* $SPARKTK_HOME && \
    ln -s /usr/local/daaltk-core-* $DAALTK_HOME && \
    rm -rf /usr/local/$TKLIBS_INSTALLER /usr/local/*.tar.gz


# Install spark-tk package mainly to fix the graphframes install
RUN cd $SPARKTK_HOME && \
    chmod +x install.sh && \
    sync && \
    ./install.sh


# Create hadoop user with UID=1000 and in the 'users' group
ENV NB_USER "hadoop"
ENV SHELL "/bin/bash"
ENV NB_UID "1000"
ENV HOME "/home/$NB_USER"
RUN useradd $NB_USER


# Configure container startup
EXPOSE 8888
WORKDIR $HOME/jupyter
RUN mkdir -p $HOME/jupyter


COPY assets/start-notebook.sh /usr/local/bin/
COPY assets/jupyter_notebook_config.py $HOME/.jupyter/
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]


# Final cleanup
RUN \
    rm -rf /tmp/* && \
    rm -rf $HOME/jupyter/examples/pandas-cookbook/Dockerfile && \
    rm -rf $HOME/jupyter/examples/pandas-cookbook/README.md


# Copy the example notebooks
COPY jupyter-default-notebooks/notebooks $HOME/jupyter


# Final cleanup
RUN \
    rm -rf $HOME/jupyter/examples/pandas-cookbook/Dockerfile && \
    rm -rf $HOME/jupyter/examples/pandas-cookbook/README.md


# Fix the entry point
COPY jupyter-startup.sh /usr/local/bin/jupyter-startup.sh
RUN chmod +x /usr/local/bin/jupyter-startup.sh
CMD ["/usr/local/bin/jupyter-startup.sh"]


RUN mkdir -p $HOME/.jupyter/nbconfig

ENV PASSWORD "jupyter"


# enable some additional jupyter server extentions
RUN jupyter serverextension enable sparktk_ext && \
    jupyter serverextension enable --py jupyter_spark && \
    jupyter nbextension install --py jupyter_spark && \
    jupyter nbextension enable --py jupyter_spark && \
    jupyter nbextension enable --py widgetsnbextension

