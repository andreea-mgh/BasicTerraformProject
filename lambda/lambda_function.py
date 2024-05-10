import json
import boto3 # type: ignore
import os
from datetime import datetime

sns = boto3.client('sns')

def calculeaza_varsta(data_nasterii):
    azi = datetime.today()
    data_nasterii = datetime.strptime(data_nasterii, '%d.%m.%Y')
    varsta = azi.year - data_nasterii.year - ((azi.month, azi.day) < (data_nasterii.month, data_nasterii.day))
    return varsta

def lambda_handler(event, context):
    try:
        mesaj = json.loads(event['Records'][0]['body'])
        print(mesaj)
        nume = mesaj['nume']
        data_nasterii = mesaj['data nasterii']
        
        if data_nasterii:
            
            varsta = calculeaza_varsta(data_nasterii)
            print("Nume:", nume, "\nVarsta:", varsta)
            notification = "new signup \nNume: {} \nVarsta: {}".format(nume, varsta)
                
            try:
                sns.publish(
                    TopicArn=os.environ['SNS_TOPIC_ARN'],
                    Message=notification
                )
            except Exception as e:
                print("SNS publish exception:", e)
            
            
        else:
            print("Mesajul nu are atribut pentru data nasterii.")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Message processed')
        }
    
    except Exception as e:
        print(e)
        return
        
