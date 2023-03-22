import os
import boto3
from botocore.exceptions import ClientError
import pymysql
import csv
from aws_lambda_powertools import Logger, Tracer
from botocore.client import Config


logger = Logger()
tracer = Tracer()

s3 = boto3.client('s3', config=Config(signature_version='s3v4'))
secretsmanager = boto3.client('secretsmanager')

S3_BUCKET_NAME = os.environ['S3_BUCKET_NAME']
logger.info(S3_BUCKET_NAME)
S3_OBJECT_KEY = os.environ['S3_OBJECT_KEY']
logger.info(S3_OBJECT_KEY)
RDS_HOST = os.environ['RDS_HOST']
logger.info(RDS_HOST)
RDS_DATABASE = os.environ['RDS_DATABASE']
logger.info(RDS_DATABASE)
RDS_TABLE = os.environ['RDS_TABLE']
logger.info(RDS_TABLE)
SECRETS_NAME = os.environ['SECRETS_NAME']
logger.info(SECRETS_NAME)
REGION = os.environ['REGION']
logger.info
file_name = "Random_emails.csv"
local_file_path = "/tmp/Random_emails.csv"

def table_exists(cursor, table_name):
    """Return True if the table exists, False otherwise."""
    cursor.execute(f"SHOW TABLES LIKE '{RDS_TABLE}'")
    result = cursor.fetchone()
    return result is not None

def create_table(cursor,table_name):
    """Create the table if it does not exist."""
    cursor.execute(
        f"CREATE TABLE {RDS_TABLE} ("
        "id INT AUTO_INCREMENT,"
        "emails VARCHAR(255),"
        "PRIMARY KEY (id)"
        ")"
    )

@logger.inject_lambda_context(log_event=True)
@tracer.capture_method
def lambda_handler(event, context):
    try:
        secret_name = SECRETS_NAME
        region_name = REGION
        logger.info('Create Clients')
        session = boto3.session.Session()
        client = session.client(
            service_name='secretsmanager',
            region_name=region_name,
        )

        try:
            logger.info('Get secret value')
            get_secret_value_response = client.get_secret_value(
                SecretId=secret_name
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                logger.info("The requested secret " + secret_name + " was not found")
            elif e.response['Error']['Code'] == 'InvalidRequestException':
                logger.info("The request was invalid due to:", e)
            elif e.response['Error']['Code'] == 'InvalidParameterException':
                logger.info("The request had invalid params:", e)
            elif e.response['Error']['Code'] == 'DecryptionFailure':
                logger.info("The requested secret can't be decrypted using the provided KMS key:", e)
            elif e.response['Error']['Code'] == 'InternalServiceError':
                logger.info("An error occurred on service side:", e)
        else:
            logger.info('In get_secret_value_response')
            # Secrets Manager decrypts the secret value using the associated KMS CMK
            # Depending on whether the secret was a string or binary, only one of these fields will be populated
            if 'SecretString' in get_secret_value_response:
                logger.info('Inside IF')
                text_secret_data = get_secret_value_response['SecretString']
            else:
                logger.info('Inside ELSE')
                binary_secret_data = get_secret_value_response['SecretBinary']
        
        logger.info('Connecting to database')
        logger.info(text_secret_data)
        # Connect to the database
        conn = pymysql.connect(host=RDS_HOST,
                               #TODO: fix
                               user="admin",
                               password=text_secret_data,
                               db=RDS_DATABASE,
                               connect_timeout=10)
        logger.info('Connected to database')

        logger.info('Starting table creation')
        # Check if the table exists and create it if it does not
        with conn.cursor() as cursor:
            if not table_exists(cursor, RDS_TABLE):
                create_table(cursor, RDS_TABLE)
        logger.info('Completed table creation')

        s3_object = s3.get_object(Bucket=S3_BUCKET_NAME, Key=S3_OBJECT_KEY)
        file_content = s3_object['Body'].read().decode('utf-8')

        # Read the CSV content and insert it into the MySQL RDS instance
        csv_data = csv.reader(file_content.splitlines())
        headers = next(csv_data)

        with conn.cursor() as cursor:
            for row in csv_data:
                insert_query = f"INSERT IGNORE INTO {RDS_TABLE} (id, emails) VALUES (%s, %s)"
                cursor.execute(insert_query, tuple(row))
                conn.commit()

        logger.info('Completed uploading values to database')

        # Commit the changes and close the connection
        conn.close()

        return {
            'statusCode': 200,
            'body': 'CSV file uploaded to RDS MySQL instance'
        }
    except Exception as e:
        logger.info(e)
        return {
            'statusCode': 500,
            'body': 'An error occurred while uploading CSV file to RDS MySQL instance'
        }

###############################################################