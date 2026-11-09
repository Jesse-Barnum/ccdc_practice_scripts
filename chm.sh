# 1. Move the files to Phineas's desktop
mv /home/ubuntu/Desktop/Forensics /home/phineas/Desktop/
mv /home/ubuntu/Desktop/ScoreReport.html /home/phineas/Desktop/
mv /home/ubuntu/Desktop/README.txt /home/phineas/Desktop/ 2>/dev/null

# 2. Grant Phineas ownership of his desktop files
chown -R phineas:phineas /home/phineas/Desktop/
chmod 644 /home/phineas/Desktop/ScoreReport.html

# 3. Update the Python script's hardcoded paths using sed
sed -i 's|/home/ubuntu/Desktop/ScoreReport.html|/home/phineas/Desktop/ScoreReport.html|' /opt/OWCA_Engine/scoring_engine.py
sed -i 's|/home/ubuntu/Desktop/Forensics|/home/phineas/Desktop/Forensics|' /opt/OWCA_Engine/scoring_engine.py

# 4. Restart the background engine to apply the new paths
systemctl restart owca-engine.service
