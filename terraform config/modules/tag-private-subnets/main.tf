# Add Kubernetes-specific tags to private subnets
# Tag only private subnets 0 (us-west-2a) and 1 (us-west-2b) with Kubernetes tags

locals {
  tags_to_apply = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"      = "1"
    "Name"                                 = "private-subnet"
  }

  # 1. Strictly isolate only the first two indices from your incoming variable array
  subnet_indices = range(length(var.subnet_ids) > 2 ? 2 : length(var.subnet_ids))

  # 2. Build a flat, rock-solid map for the for_each block
  subnet_tag_pairs = merge([
    for s_idx in local.subnet_indices : {
      for tag_key, tag_value in local.tags_to_apply :
      # Construct a unique, predictable key combining the index and the tag key
      "idx_${s_idx}_tag_${tag_key}" => {
        subnet_id = var.subnet_ids[s_idx]
        tag_key   = tag_key
        tag_value = tag_value
      }
    }
  ]...) # The '...' ellipsis flattens the nested loops into a single map level
}

resource "aws_ec2_tag" "private_subnet_eks_tags" {
  for_each = local.subnet_tag_pairs

  # This value safely tracks dependencies even when the input IDs are unknown during plan
  resource_id = each.value.subnet_id 
  
  key   = each.value.tag_key
  value = each.value.tag_value
}