# from variables

locals {
  env                   = var.splunktargetenv
  instance-type-indexer = (local.env == "min" ? var.instance-type-indexer-min : var.instance-type-indexer-default)
  instance-type-iuf     = (local.env == "min" ? var.instance-type-iuf-min : var.instance-type-iuf-default)
  instance-type-ihf     = (local.env == "min" ? var.instance-type-ihf-min : var.instance-type-ihf-default)
  instance-type-hf      = (local.env == "min" ? var.instance-type-hf-min : var.instance-type-hf-default)
  instance-type-std     = (local.env == "min" ? var.instance-type-std-min : var.instance-type-std-default)
  instance-type-cm      = (local.env == "min" ? var.instance-type-cm-min : var.instance-type-cm-default)
  instance-type-mc      = (local.env == "min" ? var.instance-type-mc-min : var.instance-type-mc-default)
  instance-type-ds      = (local.env == "min" ? var.instance-type-ds-min : var.instance-type-ds-default)
  instance-type-sh      = (local.env == "min" ? var.instance-type-sh-min : var.instance-type-sh-default)
  ds-nb                 = (var.ds-enable ? 1 : 0)
  mc-nb                 = (var.mc-enable ? 1 : 0)
}


# prepare buckets


resource "null_resource" "createbuckets-directories" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "./scripts/createbuckets-directories.sh"
  }
}

resource "null_resource" "build-idx-scripts" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "./scripts/build-idx-scripts.sh idx-site;./scripts/build-idx-scripts.sh idx-site1;./scripts/build-idx-scripts.sh idx-site2;./scripts/build-idx-scripts.sh idx-site3"
  }
  depends_on = [null_resource.createbuckets-directories]
}

resource "null_resource" "build-nonidx-scripts" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "./scripts/build-nonidx-scripts.sh ${var.cm}"
  }
  depends_on = [null_resource.createbuckets-directories]
}

resource "null_resource" "bucket_sync" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "./scripts/copytos3.sh ${aws_s3_bucket.s3_install.id} ${aws_s3_bucket.s3_backup.id}"
    #command = " aws s3 sync ./packaged s3://${aws_s3_bucket.s3_install.id}/packaged/ --storage-class STANDARD_IA; aws s3 sync ./splunkconf-backup s3://${aws_s3_bucket.s3_backup.id}/splunkconf-backup/ --storage-class STANDARD_IA; aws s3 sync ./install s3://${aws_s3_bucket.s3_install.id}/install/ --storage-class STANDARD_IA"
    #command = " aws s3 sync ./packaged s3://${aws_s3_bucket.s3_install.arn}/packaged/ --storage-class STANDARD_IA; aws s3 sync ./splunkconf-backup s3://${aws_s3_bucket.s3_backup.arn}/splunkconf-backup/ --storage-class STANDARD_IA; aws s3 sync ./install s3://${aws_s3_bucket.s3_install.arn}/install/ --storage-class STANDARD_IA"
    #    command = " aws s3 sync ./packaged s3://${aws_s3_bucket.s3_install.bucket_regional_domain_name}/packaged/ --storage-class STANDARD_IA; aws s3 sync ./splunkconf-backup s3://${aws_s3_bucket.s3_backup.bucket_regional_domain_name}/splunkconf-backup/ --storage-class STANDARD_IA; aws s3 sync ./install s3://${aws_s3_bucket.s3_install.bucket_regional_domain_name}/install/ --storage-class STANDARD_IA"
  }
  #depends_on = [null_resource.build-idx-scripts,null_resource.build-cm-scripts,aws_s3_bucket_lifecycle_configuration.s3_install_lifecycle,aws_s3_bucket_lifecycle_configuration.s3_backup_lifecycle,aws_s3_bucket_versioning.s3_install_versioning,aws_s3_bucket_versioning.s3_backup_versioning]
  depends_on = [null_resource.build-idx-scripts, null_resource.build-nonidx-scripts, aws_s3_bucket_lifecycle_configuration.s3_install_lifecycle, aws_s3_bucket_lifecycle_configuration.s3_backup_lifecycle, aws_s3_bucket_versioning.s3_install_versioning, aws_s3_bucket_versioning.s3_backup_versioning]
}

