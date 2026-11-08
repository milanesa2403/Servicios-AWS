# Infraestructura: Amazon CloudFront vs AWS Global Accelerator

Terraform para desplegar las dos arquitecturas de la comparativa del proyecto Plataforma Global de Reclutamiento Minero (G3).

| Carpeta | Qué contiene |
|---|---|
| `modules/backend` | VPC con 2 AZ + Application Load Balancer + 2 EC2 (lo usan A y B) |
| `modules/frontend-s3` | Bucket S3 privado con la web (solo A) |
| `arquitectura-a-cloudfront` | CloudFront con 2 orígenes (`/*` a S3 con OAC, `/api/*` al ALB) + WAF, en us-east-2 |
| `arquitectura-b-accelerator` | Global Accelerator con 2 IPs fijas + backend en us-east-2 y sa-east-1 |
| `iam/politica-comparativa.json` | Política IAM de ejemplo con los permisos necesarios |

## Qué sirve cada EC2
Cada EC2 instala Apache al arrancar (`modules/backend/user_data.sh`) y publica:
- `/` (`index.html`): "Plataforma de Reclutamiento Minero" con la región, la zona y la instancia.
- `/api/health`: `ok`, para el health check del ALB y de Global Accelerator.
- `/api/info`: región, zona e instancia en JSON, para ver qué servidor respondió.

En A, `/` lo sirve S3 por CloudFront y `/api/*` llega a las EC2.

## Región

Todo va en **us-east-2** (la región que pidió el profesor). B usa además **sa-east-1** como segunda región.
Excepciones de AWS que no se pueden cambiar: el WAF de CloudFront siempre se crea en us-east-1 y la API de
Global Accelerator está en us-west-2. Si su política IAM limita regiones con `aws:RequestedRegion`, usen
`iam/politica-comparativa.json`: limita EC2 y ELB a us-east-2 y sa-east-1, y deja sin condición de región a
CloudFront, WAF y Global Accelerator.

## Requisitos
- AWS CLI configurada (`aws sts get-caller-identity`) con permisos de administrador.
- Terraform 1.10 o superior.

## Arquitectura A: CloudFront
```bash
cd arquitectura-a-cloudfront
terraform init
terraform apply      # 5-10 min
terraform output     # url = https://dxxxx.cloudfront.net
terraform destroy
```

## Arquitectura B: Global Accelerator
```bash
cd arquitectura-b-accelerator
terraform init
terraform apply
terraform output     # ips_estaticas y url del acelerador
terraform destroy
```

Las EC2 tardan unos 3 minutos en instalar Apache después del `apply`.
Costo aproximado: A ~0.07 USD/h y B ~0.18 USD/h. Destruir al terminar las pruebas.

## Fuentes

Documentación oficial en la que se basa el código de cada carpeta.

### General (Terraform y proveedor de AWS)
- Proveedor de AWS para Terraform: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Módulos de Terraform: https://developer.hashicorp.com/terraform/language/modules
- Varios proveedores con alias (usado para 2 regiones en B y el WAF en A): https://developer.hashicorp.com/terraform/language/providers/configuration
- Variables y outputs: https://developer.hashicorp.com/terraform/language/values/variables y https://developer.hashicorp.com/terraform/language/values/outputs

### `modules/backend` (VPC, ALB y EC2)
- VPC: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
- Subredes: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
- Internet gateway: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
- Tabla de rutas: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
- Security groups y reglas: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group y https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule
- Instancia EC2: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
- AMI de Amazon Linux 2023 desde SSM: https://docs.aws.amazon.com/linux/al2023/ug/ec2.html
- Rol IAM y perfil de instancia: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role y https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
- Application Load Balancer: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
- Target group y health check: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group y https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html
- Listener del ALB: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener

### `modules/backend/user_data.sh` (Apache en la EC2)
- User data (script al arrancar la EC2): https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
- Metadatos de la instancia con IMDSv2 (región, zona e ID): https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
- Apache en Amazon Linux 2023: https://docs.aws.amazon.com/linux/al2023/ug/ec2-lamp-amazon-linux-2023.html
- Directivas de Apache `ForceType` y `Header`: https://httpd.apache.org/docs/2.4/mod/core.html#forcetype y https://httpd.apache.org/docs/2.4/mod/mod_headers.html

### `modules/frontend-s3` (S3 privado)
- Bucket S3: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
- Bloqueo de acceso público: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
- Cifrado del bucket: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
- Objetos en S3: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object

### `arquitectura-a-cloudfront`
- Distribución de CloudFront: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution
- Origin Access Control (S3 privado): https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control y https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
- Políticas de caché administradas: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html
- Políticas de origin request administradas: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-origin-request-policies.html
- Comportamientos por ruta (`/api/*`): https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-values-specify.html
- Prefix list de CloudFront para el security group del ALB: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/LocationsOfEdgeServers.html
- WAF (web ACL): https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl
- Regla de límite por IP del WAF: https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-rate-based.html
- Política del bucket: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy

### `arquitectura-b-accelerator`
- Qué es Global Accelerator: https://docs.aws.amazon.com/global-accelerator/latest/dg/what-is-global-accelerator.html
- Acelerador: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/globalaccelerator_accelerator
- Listener: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/globalaccelerator_listener
- Endpoint groups, health checks y traffic dial: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/globalaccelerator_endpoint_group y https://docs.aws.amazon.com/global-accelerator/latest/dg/about-endpoint-groups-traffic-dial.html

### `iam/politica-comparativa.json`
- Condición `aws:RequestedRegion`: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html
