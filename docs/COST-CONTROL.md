# Cost Control (read once, follow always)

## Where the money comes from

| Cloud | While up (approx) | While down |
|---|---|---|
| AWS | EKS $0.10/h, plus 2x t3.medium spot ~$0.03/h, plus NAT ~$0.045/h, so roughly **$0.18/h (about $4/day)** | $0 (state in S3 is cents) |
| Azure | 2x B2s_v2 ~$0.08/h plus the LB, roughly **$2/day**, paid by the $200 credit | $0 |
| Route 53 | Private hosted zone $0.50/mo, plus 2 health checks ~$1.50/mo | same |

Practical total for the build week: **AWS around $10 to $15 of real money** (the
only cloud you actually pay for), Azure entirely on the free credit, DNS a couple
of dollars a month. No domain was purchased; the failover uses a private zone.

## Rules

1. **AWS never stays up idle.** Run `make down-aws` at the end of every session. A rebuild takes about 15 minutes and the ApplicationSet re-deploys the app automatically once the cluster re-registers.
2. The AKS hub can stay up for the whole build week on the credit, but take it down for multi-day gaps with `make down-azure`.
3. Set billing alerts on day 0:
   - AWS: a $15 budget with alerts at 50, 80, and 100 percent.
   - Azure: Cost Management, a $50 budget on the subscription.
4. The Azure trial does not auto-charge. Services stop when the credit runs out unless you upgrade. The alerts keep you honest anyway.
5. After the project ships: `make down-all`, then keep the repo, screenshots, and demo video. You can bring the whole platform back in about 30 minutes for any interview. That is the point of IaC.

## Weekly checklist

- [ ] `terraform state list` empty in aws/ after teardown?
- [ ] EC2, EKS, ELB, and NAT consoles empty?
- [ ] Azure resource group deleted when not needed?
- [ ] Route 53 health checks deleted when not demoing (`make down-dns`)?
