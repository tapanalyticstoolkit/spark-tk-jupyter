# spark-tk-jupyter

Jupyter notebook docker built on top of Clear Linux*.

>The final images contains pandas-cookbook example notebooks from this repo:
https://github.com/jvns/pandas-cookbook

## What's new

This is the initial release of the `spark-tk-jupyter` repo.

## Known issues

None.

## Building the image
1. Pull all the submodules:  
    `git submodule update --init --recursive`  
2. Build the image:  
    `sudo docker build --tag=spark-tk-jupyter`  

   Or if you are behind a proxy use this:  
    ```
    sudo docker build --build-arg HTTP_PROXY=$http_proxy --build-arg HTTPS_PROXY=$http_proxy --build-arg NO_PROXY=$no_proxy --build-arg http_proxy=$http_proxy --build-arg https_proxy=$http_proxy --build-arg no_proxy=$no_proxy --tag=spark-tk-jupyter
    ```  

## Run the image:  

    sudo docker run -p 8900:8888 YOUR_JUPYTER_IMAGE_TAG

##Features

- PySpark, Spark Shell
- Jupyter REST APIs for upload and running PySpark/SparkTK scripts
- ATK libraries
- Spark-TK libraries
- Python and Pip 2.7
- Examples notebooks from the project `jupyter-default-notebooks`

## REST APIs provided

### /upload
- Currently the only way to upload files to Jupyter is using the upload Form.
- After each attempt to upload, the file(s) are loaded into a directory format like "uploads/dddd" where d is a digit.

```
curl http://JUPYTER_NOTEBOOK_URL/upload -F "filearg=@/home/username/frame-basics.py"  
```  

```
curl http://JUPYTER_NOTEBOOK_URL/upload -F "filearg=@/home/username/frame-basics.py" -F "filearg=@/home/username/frame-advanced.py"  
```

### /delete
```
curl http://JUPYTER_NOTEBOOK_URL/delete -d "app-path=uploads/0001" 
```

### /rename
```
curl http://JUPYTER_NOTEBOOK_URL/rename -d "app-path=uploads/0001" -d "dst-path=uploads/myapp"  
```

### /spark-submit
```
curl http://JUPYTER_NOTEBOOK_URL/spark-submit -d "driver-path=uploads/0001/frame-basics.py"  
```

### /logs
```
curl http://JUPYTER_NOTEBOOK_URL/logs -d "app-path=uploads/0001" -d "offset=1" -d "n=100"  
```

### /status
```
curl http://JUPYTER_NOTEBOOK_URL/status -d "app-path=uploads/0001"  
```

