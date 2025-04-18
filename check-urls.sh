#!/bin/bash

# List of URLs (you can store this in a separate file if preferred)
URLS=$(cat <<EOF
http://nolo-stg1.nolodev.tech/
http://stg1.nolo.com/
http://stg1.employmentlawfirms.com/
http://stg1.foreclosurelawfirms.com/
http://stg1.landlordtenantlawfirms.com/
http://stg1.medicalmalpractice.com/
http://stg1.personalinjurylawyer.com/
http://stg1.realestatelawyers.com/
http://stg1.smallbusinesslawfirms.com/
http://stg1.socialsecuritylawfirms.com/
http://stg1.taxationlawfirms.com/
http://stg1.thebankruptcysite.org/
http://stg1.trafficviolationlawfirms.com/
http://stg1.usimmigrationlawyers.com/
http://stg1.workerscompensationlawfirms.com/
http://stg1.wrongfuldeathlawfirms.com/
http://stg1.wrongfulterminationlaws.com/
http://stg1.filingforbankruptcyonline.com/
http://stg1.babyformula.alllaw.com/
http://stg1.bedsores.alllaw.com/
http://stg1.alllaw.com/
http://stg1.sexualabuse.alllaw.com/
http://stg1.churchsexualabuse.alllaw.com/
http://stg1.cpap.alllaw.com/
http://stg1.earplug.personalinjurylawyer.com/
http://stg1.ivc.personalinjurylawyer.com/
http://stg1.paraquat.alllaw.com/
http://stg1.vaping.personalinjurylawyer.com/
http://stg1.asbestoslawfirms.com/
http://stg1.weedkiller.personalinjurylawyer.com/
http://stg1.rideshareassault.alllaw.com/
http://stg1.lawfirms.com/
http://stg1.dui.drivinglaws.org/
http://stg1.floridainjurynetwork.com/
http://stg1.personalinjurylawyerlocator.com/
http://stg1.chapter7lawyerlocator.com/
http://stg1.childcustodylawyerlocator.com/
http://stg1.custodylawyerlocator.com/
http://stg1.criminallawyerlocator.com/
http://stg1.owilawyerlocator.com/
http://stg1.mylawyerlocator.com/
http://stg1.medicalmalpracticelawyerlocator.com/
http://stg1.motorcycleaccidentlawyerlocator.com/
http://stg1.truckaccidentlawyerlocator.com/
http://stg1.autoaccidentlawyerlocator.com/
http://stg1.caraccidentlawyerlocator.com/
http://stg1.willslawyerlocator.com/
http://stg1.workerscompensationlawyerlocator.com/
http://stg1.workerscomplawyerlocator.com/
http://stg1.alabamalawyerlocator.com/
http://stg1.albuquerquelawyerlocator.com/
http://stg1.albanylawyerlocator.com/
http://stg1.bostonlawyerlocator.com/
http://stg1.baltimorelawyerlocator.com/
http://stg1.denverlawyerlocator.com/
http://stg1.attorneys.com/
http://stg1.lawyerlocator.com/
http://stg1.martindalellc.com/
http://stg1.cdn.nolo.com/
http://stg1.m.nolo.com/
http://stg1.divorcenet.com/
http://stg1.accountantsfinder.com/
http://stg1.accountantnetworks.com/
http://stg1.nololawlibrary.com/
http://stg1.thedivorcelawyersdirectory.com/
http://stg1.experthub.com/
http://stg1.experthub.net/
http://stg1.willsandtrustslawfirms.com/
http://stg1.referral.lawfirms.com/
http://stg1.chiropractors.org/
http://stg1.member.nolo.com/
http://stg1.www1.divorcenet.com/
http://stg1.disabilitysecrets.com/
http://stg1.criminaldefenselawyer.com/
http://stg1.all-about-car-accidents.com/
http://stg1.consumerprotectionlawfirms.com/
http://stg1.sexualharassmentlawfirms.com/
http://stg1.caraccidentattorneys.com/
http://stg1.disabilitylawyers.com/
http://stg1.totalattorneys.com/
http://stg1.totalbankruptcy.com/
http://stg1.nolodev.tech/
http://leads-lawyers-com-nolo-stg1.nolodev.tech/
EOF
)

echo "🔍 Checking DNS resolution and HTTP status for each URL"
echo "-------------------------------------------------------"

for url in $URLS; do
  domain=$(echo "$url" | awk -F/ '{print $3}')  # Extract domain from URL

  if host "$domain" > /dev/null 2>&1; then
    status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    echo "✅ $url --> HTTP $status"
  else
    echo "❌ $url --> DNS resolution failed"
  fi
done
