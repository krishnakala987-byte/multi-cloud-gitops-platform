# Cost Control (read once, follow always)

## Where money comes from
| Cloud | While UP (approx) | While DOWN |
|---|---|---|
| AWS | EKS $0.10/h + 2× t3.medium spot ~$0.03/h + NAT ~$0.045/h ≈ **$0.18/h (~$4/day)** | $0 (S3 state: cents) |
| Azure | 2× B2s ~$0.08/h + LB ≈ **~$2/day** — paid by $200 credit | $0 |
| Route 53 | Hosted zone $0.50/mo + 2 health checks ~$1.50/mo | same |

Practical week total: **AWS $10–15 real money** (only cloud you pay), Azure fully on credit.

## Rules
1. **AWS never sleeps up.** `make down-aws` ends every session. Rebuild is 15 min and the ApplicationSet re-deploys automatically on re-registration.
2. AKS hub can stay up all build week (credit), but down it for multi-day gaps: `make down-azure`.
3. Billing alerts on day 0:
   - AWS: Budget $15, alert at 50/80/100%.
   - Azure: Cost Management → Budget $50 on the subscription.
4. The Azure trial doesn't auto-charge (services stop at credit end) — alerts keep you honest anyway.
5. After the project ships: `make down-all`, keep repo + screenshots + video. You can resurrect the whole platform in 30 minutes for any interview: that's IaC.

## Weekly checklist
- [ ] `terraform state list` empty in aws/ after down?
- [ ] EC2/EKS/ELB/NAT consoles empty?
- [ ] Azure resource group deleted when not needed?
- [ ] Route 53 health checks deleted when not demoing (`make down-dns`)?
