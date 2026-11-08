# Infraestructura: CloudFront vs Global Accelerator

Código de Terraform para levantar las dos arquitecturas que comparamos en el proyecto Plataforma Global de Reclutamiento Minero (G3).

## Qué hay en cada carpeta

- `modules/backend`: la VPC con 2 zonas de disponibilidad, el balanceador (ALB) y 2 EC2. Lo usan las dos arquitecturas.
- `modules/frontend-s3`: el bucket S3 privado donde está la página web. Solo lo usa la A.
- `arquitectura-a-cloudfront`: CloudFront con dos orígenes (la web sale de S3 con OAC, para que el bucket siga privado, y `/api/*` va al ALB), más un WAF. Todo en us-east-2.
- `arquitectura-b-accelerator`: Global Accelerator con 2 IPs fijas y un backend en us-east-2 y otro en sa-east-1.
- `iam/politica-comparativa.json`: una política IAM de ejemplo con los permisos que hacen falta.

## Qué hace cada EC2

Al arrancar instala Apache (el script está en `modules/backend/user_data.sh`) y responde en tres rutas:

- `/`: una página sencilla que dice en qué región, zona e instancia está corriendo.
- `/api/health`: responde `ok`. Es la ruta que usan los health checks del ALB y de Global Accelerator.
- `/api/info`: lo mismo que la página, pero en JSON. Sirve para ver qué servidor contestó.

En la arquitectura A la página la entrega S3 a través de CloudFront, y a las EC2 solo llegan las peticiones de `/api/*`.

## Regiones

Todo está en us-east-2 porque fue la región que pidió el profesor. La arquitectura B usa también sa-east-1 como segunda región.

Hay dos cosas de AWS que no se pueden mover de sitio: el WAF de CloudFront siempre se crea en us-east-1, y la API de Global Accelerator está en us-west-2. Si la cuenta limita las regiones con `aws:RequestedRegion`, hay que usar `iam/politica-comparativa.json`. Esa política deja EC2 y ELB solo en us-east-2 y sa-east-1, y no pone límite de región a CloudFront, WAF ni Global Accelerator.

## Qué necesitas

- AWS CLI configurada y funcionando, con permisos de administrador.
- Terraform.

## Cómo desplegar la arquitectura A

```bash
cd arquitectura-a-cloudfront
terraform init
terraform apply      # tarda entre 5 y 10 min
terraform output     # muestra la url: https://dxxxx.cloudfront.net
terraform destroy    # para borrar todo al terminar
```

## Cómo desplegar la arquitectura B

```bash
cd arquitectura-b-accelerator
terraform init
terraform apply
terraform output     # muestra las IPs fijas y la url del acelerador
terraform destroy    # para borrar todo al terminar
```

Después del `apply`, las EC2 tardan unos 3 minutos en instalar Apache, así que si la página no abre al principio, hay que esperar un poco.

El costo aproximado es de 0.07 USD por hora para la A y 0.18 USD por hora para la B. Conviene hacer `destroy` apenas terminen las pruebas para no gastar de más.

## Dónde buscamos la información

- Proveedor de AWS para Terraform: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Varios proveedores con alias (para las 2 regiones en B y el WAF en A): https://developer.hashicorp.com/terraform/language/providers/configuration
- Health checks del target group del ALB: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html
- Metadatos de la instancia con IMDSv2: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
- S3 privado con Origin Access Control: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
- Regla de límite por IP en WAF: https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-rate-based.html
- Qué es Global Accelerator: https://docs.aws.amazon.com/global-accelerator/latest/dg/what-is-global-accelerator.html
- Endpoint groups y traffic dial: https://docs.aws.amazon.com/global-accelerator/latest/dg/about-endpoint-groups-traffic-dial.html
- Condición `aws:RequestedRegion` en IAM: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html


### `iam/politica-comparativa.json`
- Condición `aws:RequestedRegion`: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html
