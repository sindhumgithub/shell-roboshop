#!/bin/bash


USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=172.31.26.18
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"              # /var/log/shell-script/16-logs.log


mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE


if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1                                  # failure is other than 0
fi


VALIDATE(){          # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}


##### NODEJS Shell Script #####
dnf module disable nodejs -y &>>$LOG_FILE    
VALIDATE $? "Disabling existing nodejs software"


dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling new nodejs20 software"
echo -e "Installing NODEJS  20 ...... $G SUCCESS $N"




dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs software"




id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating System User"
else
    echo -e "user already exist..... $Y SKIPPING $N"
fi


mkdir -p /app  # To check whether the /app directory has been created or not using -p flag
VALIDATE $? "Creating app directory"


curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Catalogue Application"


cd /app
VALIDATE $? "Moving to /app directory"


rm -rf /app/*
VALIDATE $? "Removing existing code"


unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzip catalogue"


npm install &>>$LOG_FILE
VALIDATE $? "Install dependencies"


cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying systemctl service"


systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enable catalogue"
echo -e "Catalogue application setup...... $G SUCCESS $N"


cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy Mongo repo"


dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install mongodb client"


INDEX=$(mongosh mongodb.daws86s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")  #checking whether the DB is created or not in mongodb....
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi


systemctl restart catalogue
echo -e "Loading Products ...... $G SUCCESS $N"
VALIDATE $? "Restarted Catalogue"