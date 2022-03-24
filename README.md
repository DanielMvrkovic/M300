# laC Dokumentation
## Inhaltsverzeichnis
- [laC Dokumentation](#lac-dokumentation)
  - [Inhaltsverzeichnis](#inhaltsverzeichnis)
  - [1. Auftrag](#1-auftrag)
    - [1.1 Aufgabenstellung](#11-aufgabenstellung)
    - [1.2 Anforderungen](#12-anforderungen)
  - [2. Einführung Projekt](#2-einführung-projekt)
    - [2.1 Umgebung](#21-umgebung)
    - [2.2 Funktionen VM1](#22-funktionen-vm1)
    - [2.3 Funktionen VM2](#23-funktionen-vm2)
    - [2.4 Grafik](#24-grafik)
  - [3. Code Erklärung](#3-code-erklärung)
    - [3.1 Aufteilung](#31-aufteilung)
    - [3.2 Vagrantfile](#32-vagrantfile)
    - [3.3 NFS Konfiguration](#33-nfs-konfiguration)
    - [3.4 Webserver Konfiguration](#34-webserver-konfiguration)
    - [3.5 HTML File](#35-html-file)
    - [3.6 VM2 Konfiguration](#36-vm2-konfiguration)
  - [4. Quellenangaben](#4-quellenangaben)

## 1. Auftrag
### 1.1 Aufgabenstellung
Sie erstellen -auf Basis von VirtualBox/Vagrant-ein selbst gewähltes«Infrastructure as Code»Projekt, indem sie einen Service oder Serverdienst automatisieren.

Teamarbeit ist erwünscht.Die Implementation des IaC-Projektserfolgt hingegenals Einzelarbeit. Der erstellte Code sowie die gesamte Dokumentation wird versioniertaufGitHub,hinterlegt und der Lehrpersonzugänglich gemacht (Lese-Rechte).

Das Internet ist eine wichtige Ressource für solche Projekte. Entsprechend dürfen sie auch Codebeispiele aus dem Internet verwenden, sofern sie entsprechende Quellenangaben machen.

Der verwendete Code muss von ihnen vollständigdokumentiert sein, das gilt auch für Code, mindestens in groben Zügen, welchen sie aus fremden Quellen verwenden. 

Das bedeutet sie können über den verwendeten Code Auskunft geben.

### 1.2 Anforderungen
- Wiederholbar und konsistent ausführbarauf jedem Rechnerwelcher Vagrant und 
-  VirtualBox installiert hat•Die Entwicklungsschrittedes Codesund der 
-  Dokumentation sind in der Git Historiedurch regelmässige und dokumentierte 
  Commit nachvollziehbar. 
- Service/Dienstist von ausserhalb der VM(Bsp. über http/https)zugänglich
- Service/Dienststartetmit‘vagrant up’und ohne User-Interaktion
- Service/Dienst weist dokumentierte Sicherheitsmerkmale auf
- Die Projektdokumentationerfolgt in Markdown


## 2. Einführung Projekt
### 2.1 Umgebung
Für dieses Projekt laufen auf einem Host-Computer 
1. Eine VM mit einem Apache Webserver und NFS-Share(VM1)
2. Auf einer zweiten VM werden Backups gespeichert(VM2)
   
### 2.2 Funktionen VM1
Der Webserver auf der VM1 bietet die möglichkeit ein Formular auszufüllen, dieses Formular beinhaltet:

1. Den Namen des Dokumentes
2. Name der Person
3. Alter der Person
4. E-Mail
5. Wohnsitz(Land)
6. Nachricht

Ausserdem bietet der Webserver das Fomular als .txt file herunterzuladen. Das wird alles über HTTPS gemacht. Dazu lauft noch wie schon erwähnt ein NFS-Share, auf dem Kopien der Logs und Konfig-Dateien gespeichert.

### 2.3 Funktionen VM2
Die Aufgabe der Zweiten VM ist es, die Logs und Konfig-Dateien von der ersten VM lokal zu speichern, damit es Redundanz gibt. Dies geschiet durch einen NFS-Mount und ein paar Cronjobs, die regelmässig die Dateien in eine Directory speichern.
### 2.4 Grafik

![Alt text](https://raw.githubusercontent.com/DanielMvrkovic/M300-Service/main/M300_LB2_Umgebung_Bild.png)

## 3. Code Erklärung

### 3.1 Aufteilung
Die Umgebung wird durch fünf Dateien aufgebaut:
- Ein Vagrantfile, welcher die VMs vorbereitet
- Eine Shell-Datei um das NFS-Share einzurichten
- Eine zweite Shell-Datei um den Webserver aufzusetzen
- Eine HTML-Datei, zur Darstellung der Webseite
- Eine dritte Shell-Datei, welche auf der Zweiten VM das NFS-Share mounted und die Cronjobs fürs Backup einrichtet

Das Herz dieser Struktur ist das Vagrantfile, es startet die VMs und konfiguriert sie. Danach startet er die Shell-Dateien in den angehörigen VMs.

### 3.2 Vagrantfile
Zuerst wird defeniert welche VM aufgesetzt werden sollen. Der Name in den "" wird gebraucht, um mit der VM zu kommunizieren.
```sh
Vagrant.configure(2) do |config|
  config.vm.define "web_and_nfs" do |wn|
```
Danach werden die Parameter für die Konfigurationen während dem Aufsetzen defenierrt. Wie z.B Hostname und Betriebssystem.
```sh
wn.vm.box = "ubuntu/bionic64"
    wn.vm.hostname = 'vm1'
    wn.vm.network "forwarded_port", guest:443, host:8080, auto_correct: true
    wn.vm.network "forwarded_port", guest:443, host:443, auto_correct: true
    wn.vm.network "private_network", ip: "192.168.10.20"
    wn.vm.synced_folder ".", "/var/www/html"
```
Die Hardware angaben für den Hypervisior bestimmen.
```sh
wn.vm.provider "virtualbox" do |vb|
      vb.memory = "1024" 
      vb.cpus = "1"
    end
```
Zuletzt muss eingeben werden was Konfiguriert werden soll nach dem Aufsetzen der VM. Dazu gibt es zwei möglichkeiten. Einmal die Shell option, mit der man Commands direkt in das Vagrantfile schreibt oder man referenziert auf eine Shell-Datei, in der alle Commands drin sind. 
Auf Zeile 3 und 4 wird auf das nfs_conf.sh, welches für das einrichten des NFS-Shares zuständig ist und das apache_conf.sh, welches für das aufsetzen des Apache-Webserver zuständig ist, referenziert.

Bei Zeile 5 wird eine Lokale Datei auf die Vagrant VM übertragen.
```sh
wn.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update
    SHELL
    wn.vm.provision "shell", path: "nfs_conf.sh"
    wn.vm.provision "shell", path: "apache_conf.sh"
    wn.vm.provision "file", source: "web_input.html", destination: "/var/www/html/index.html"
  end
```
Das gleiche wird für die andere VM auch gemacht. Hier muss weniger konfiguriert werden, da es keine Services gibt. Genau gleich wie bei der ersten VM, wird auch wieder auf eine Shell-Datei referenziert.
```sh
config.vm.define "test" do |tt|
    tt.vm.box = "ubuntu/bionic64"
    tt.vm.hostname = 'vm2'
    tt.vm.network "private_network", ip: "192.168.10.30"
    tt.vm.provider "virtualbox" do |v|
      v.memory = "1024"
      v.cpus = "1"
    end
    tt.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update
      sudo apt-get install -y nfs-common
    SHELL
    tt.vm.provision "shell", path: "vm2_config.sh"
  end
```
Der ganze Code kann unter folgendem Link angeschaut werden:
https://github.com/DanielMvrkovic/M300-Service/blob/main/lb2/Vagrantfile

### 3.3 NFS Konfiguration
In den im Vagrantfile referenzierten Shell-Datei "nfs_conf.sh" steht folgendes:

Die benötigten Pakete werden heruntergeladen.
```
sudo apt-get install -y nfs-kernel-server 
sudo apt-get install -y nfs-common
```
Die Ordner für das NFS-Share werden erstellt
```
sudo mkdir -p /data/nfs/configs
sudo mkdir -p /data/nfs/configs/apache
sudo mkdir -p /data/nfs/logs
sudo mkdir -p /data/nfs/logs/apache
```
Die Berechtigung des Ordners "/Data/nfs" werden angepasst
```
chmod -R 777 /data/nfs
```
Der NFS-Share wird im "/etc/exports" eingetragen.
```sh
cat >>/etc/exports<<EOF
/data/nfs   192.168.10.30(rw,sync,no_root_squash,no_subtree_check)
EOF
```
Zuletzt wird das lokal Verzeichnis, welches im "/etc/exports" eingetragen wurde, zur verfügunggestellt und der Service gestartet.
```
sudo exportfs -a

sudo systemctl enable nfs-server

sudo systemctl start nfs-server
```
### 3.4 Webserver Konfiguration
In den im Vagrantfile referenzierten Shell-Datei "apache_conf.sh" steht folgendes:

Die benötigten Pakete werden heruntergeladen.
```
sudo apt-get -y install apache2
sudo apt-get -y install ufw
```
Die Firewall wird aktiviert und der Port 443(HTTPS) wird aufgemacht.
```
sudo ufw enable
sudo ufw allow 443/tcp
```
Das standard Apache-"Index.html" wird gelöscht
```
rm /var/www/html/index.html
```
Log-Dateien werden auf dem NFS-Share erstellt. Diese dienen momentan nur als ein Platzhalter für die Logs-Dateien des Webservers.
```
sudo touch /data/nfs/logs/apache/access.log
sudo touch /data/nfs/logs/apache/error.log
sudo touch /data/nfs/logs/apache/other_vhosts_access.log
```
Ein symlink von den Apache Log-Dateien werden, auf die vorher erstellten Dateien gemacht.
```
sudo ln -s /var/log/apache2/access.log /data/nfs/logs/apache/access.log
sudo ln -s /var/log/apache2/error.log /data/nfs/logs/apache/error.log
sudo ln -s /var/log/apache2/other_vhosts_access.log /data/nfs/logs/apache/other_vhosts_access.log
```
HTTPS wird aktiviert.
```
sudo a2ensite default-ssl.conf
sudo a2enmod ssl
sudo systemctl restart apache2
```
Cronjobs im "/etc/crontab" werden eingetragen. Diese sind dafür da, um die Konfig-Dateien vom Webserver auf das NFS-Share zu kopieren.
```sh
cat >>/etc/crontab<<EOF
*/10 * * * *    root    cp /etc/apache2/apache2.conf /data/nfs/configs/apache/apache2.conf
*/10 * * * *    root    cp /etc/apache2/sites-enabled/default-ssl.conf /data/nfs/configs/apache/default-ssl.conf
EOF
```
### 3.5 HTML File
Diese HTML-Datei stammt nicht von mir, Quelle unter [Quellenangaben](#4-quellenangaben)

Mit css wird das Layout gestaltet.
```sh
<!DOCTYPE html>
<html>
<head>
    <title>Save form Data in a Text File using JavaScript</title>
    <style>
        * {
            box-sizing: border-box;
        }
    	div {
            padding: 10px;
            background-color: #f6f6f6;
            overflow: hidden;
        }
    	input[type=text], textarea, select {
            width: 100%;
            padding: 12px;
            border: 1px solid #ccc;
            border-radius: 4px;
        }
        input[type=button]{ 
            width: auto;
            float: right;
            cursor: pointer;
            padding: 7px;
        }
    </style>
</head>
```

Input Felder und Land Auswahl werden erstellt.
```sh
<body>
    <div>
        
        <div>
            <input type="text" id="txtDocument" placeholder="Enter Name of Document" />
        </div>
        <div>
            <input type="text" id="txtName" placeholder="Enter your name" />
        </div>
        <div>
            <input type="text" id="txtAge" placeholder="Enter your age" />
        </div>
        <div>
            <input type="text" id="txtEmail" placeholder="Enter your email address" />
        </div>
        <div>
            <select id="selCountry">
                <option selected value="">-- Choose the country --</option>
                <option value="India">India</option>
                <option value="Japan">Japan</option>
                <option value="USA">USA</option>
                <option value="USA">Switzerland</option>
                <option value="USA">Australia</option>
            </select>
        </div>
        <div>
            <textarea id="msg" name="msg" placeholder="Write some message ..." style="height:100px"></textarea>
        </div>

```
Einen Button für das Downloaden der Datei wird erstellt.
```
       <div>
            <input type="button" id="bt" value="Save data to file" onclick="saveFile()" />
        </div>
    </div>
</body>
```
Die Daten der eingabe Felder werden genohmen.
```sh
let saveFile = () => {
    	
        const DocumentName = document.getElementById('txtDocument')
    	const name = document.getElementById('txtName');
        const age = document.getElementById('txtAge');
        const email = document.getElementById('txtEmail');
        const country = document.getElementById('selCountry');
        const msg = document.getElementById('msg');
```
Den Inhalt werden in Variablen gespeichert.
```sh
let NameDocu = DocumentName.value
        let data = 
            '\r Name: ' + name.value + ' \r\n ' + 
            'Age: ' +age.value + ' \r\n ' + 
            'Email: ' + email.value + ' \r\n ' + 
            'Country: ' + country.value + ' \r\n ' + 
            'Message: ' + msg.value;
```
Text wird zu einem BLOB konvertiert und ein Link wird für den Download kreiert.
```sh
const textToBLOB = new Blob([data], { type: 'text/plain' });
        const sFileName = NameDocu + '.txt';	   // The file to save the data.

        let newLink = document.createElement("a");
        newLink.download = sFileName;


        if (window.webkitURL != null) {
            newLink.href = window.webkitURL.createObjectURL(textToBLOB);
        }
        else {
            newLink.href = window.URL.createObjectURL(textToBLOB);
            newLink.style.display = "none";
            document.body.appendChild(newLink);
        }

        newLink.click();

    }
</script>
</html>
```

### 3.6 VM2 Konfiguration
Hier stehen die Konfigurationen der zweiten VM. Diese ist im Vagrantfile als "vm2_config.sh" eingetragen.

Das bentötigte Packet für NFS wird heruntergeladen und einen mount-point für das NFS-Share wird erstellt.
```sh
sudo apt install nfs-common

sudo mkdir -p /mnt/nfs-share
```
Das NFS-Share wird im "/etc/fstab" eingetragen.
```sh
cat >>/etc/fstab<<EOF
192.168.10.20:/data/nfs /mnt/nfs-share  nfs     defaults    0   0
EOF
```
NFS-Share wird gemounted.
```
sudo mount /mnt/nfs-share
```
Ordner für die Backups des Webservers werden erstellt.
```
sudo mkdir -p /backup
sudo mkdir -p /backup/log_bk
sudo mkdir -p /backup/config_bk
```
Cronjobs werden,um Daten vom NFS-Share(Konfig- und Log-Dateien) in die entsprechenden Ordner zu kopieren, ins "/etc/crontab" eingetragen. Im falle der Log-Dateien, wird auch noch komprimiert.
```sh
cat >>/etc/crontab<<EOF
*/11 * * * *    root    cp /mnt/nfs-share/configs/apache/apache2.conf /backup/config_bk/apache2.conf.bk
*/11 * * * *    root    cp /mnt/nfs-share/configs/apache/default-ssl.conf /backup/config_bk/default-ssl.conf.bk
*/11 * * * *    root    tar czf /backup/log_bk/apache.log.bk.tgz /mnt/nfs-share/logs/apache/access.log /mnt/nfs-share/logs/apache/error.log /mnt/nfs-share/logs/apache/other_vhosts_access.log
EOF
```
## 4. Quellenangaben
Link zur Html-Datei:
https://www.encodedna.com/javascript/how-to-save-form-data-in-a-text-file-using-javascript.htm
