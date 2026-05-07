<!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>Guía IPTABLES - Wiredl4bs blog</title>
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
                    <h1>iptables para novatos</h1>
<h2>Lo primero: ¿Qué es iptables?</h2>
<p><code>iptables</code> es un programa <code>CLI</code> (Command Line Interface / Por interfaz de comandos) que hace de interfaz al programa <code>netfilter</code>, estos programas se encargan de configurar el cortafuegos del núcleo de sistemas GNU/Linux mediante <strong>reglas</strong>.</p>
<ul>
<li>Existen frontends gráficos para interactuar con <code>iptables</code>.</li>
<li><code>iptables</code> se usa para IPv4 y <code>ip6tables</code> para IPv6.</li>
<li>Podemos anidar tantas cadenas como queramos.</li>
<li>Una regla puede ser simplemente un puntero a la cadena.</li>
</ul>
<p>Seguramente ahora mismo estarás pensando: ¿Para qué me voy a complicar la vida si tengo <code>firewalld</code> o <code>ufw</code>?
Y entiendo tu inquietud, hay casos en los que realmente no prima usar <code>iptables</code> en sobre otro cortafuegos pero <code>iptables</code> es mucho más configurable que cualquiera de ellos, haciéndolo mucho más versátil y flexible a tus necesidades.</p>
<h3>Arquitectura de iptables:</h3>
<p><code>iptables</code> usa tablas para organizar sus reglas. Estas tablas clasifican reglas en base al tipo de decisiones que se van a tomar. Como ejemplo, si una regla filtra un tipo de paquetes en específico se pondrá en la tabla <code>filter</code>.
En cada tabla las reglas se organizan en distintas <strong>cadenas</strong>.
Las cadenas permiten al administrador controlar donde en la entrega de un paquete se evaluará una regla.</p>
<h4>Cadenas</h4>
<p>Hay 5 cadenas en <code>iptables</code> y cada una se encarga de una tarea en específico. Son responsables de los paquetes desde que llegan hasta que o se reenvían, descartan o procesan. Estas cadenas son:
<code>PREROUTING</code>, <code>INPUT</code>, <code>FORWARD</code>, <code>OUTPUT</code>, <code>POSTROUTING</code>.</p>
<h4>Tablas</h4>
<p>Cada tabla se encarga de una cosa distinta. Hay otras 5 tablas: <code>filter</code>, <code>nat</code>, <code>mangle</code>, <code>raw</code> y <code>security</code>. Las dos primeras son las que más se usan. </p>
<ul>
<li><code>filter</code> es la más usada, se encarga de decidr si un paquete debe continuar su camino o perecer en el intento. </li>
<li><code>nat</code> se usa para redireccionar paquetes de una máquina a otra (en resumen que podemos usar una máquina como router). </li>
<li><code>mangle</code> puede ser usado para alterar la cabecera de un paquete IP de distintas maneras, se puede usar para cosas como por ejemplo ajustar el TTL (Time To Live) de un paquete. Otro tipo de cabeceras se pueden modificar de la misma manera.</li>
<li><code>raw</code> se usa para configurar excepciones del seguimiento de conexiones. </li>
<li><code>security</code> se usa para gestionar reglas especiales.</li>
</ul>
<p>Cada tabla puede hacer uso de distintas cadenas:</p>
<table>
<thead>
<tr>
<th>Tablas</th>
<th>PREROUTING</th>
<th>INPUT</th>
<th>FORWARD</th>
<th>OUTPUT</th>
<th>POSTROUTING</th>
</tr>
</thead>
<tbody>
<tr>
<td>filter</td>
<td>❌</td>
<td>✅</td>
<td>✅</td>
<td>✅</td>
<td>❌</td>
</tr>
<tr>
<td>nat</td>
<td>✅</td>
<td>❌</td>
<td>❌</td>
<td>✅</td>
<td>✅</td>
</tr>
<tr>
<td>mangle</td>
<td>✅</td>
<td>✅</td>
<td>✅</td>
<td>✅</td>
<td>✅</td>
</tr>
<tr>
<td>raw</td>
<td>❌</td>
<td>❌</td>
<td>❌</td>
<td>✅</td>
<td>✅</td>
</tr>
<tr>
<td>security</td>
<td>❌</td>
<td>✅</td>
<td>✅</td>
<td>✅</td>
<td>❌</td>
</tr>
</tbody>
</table>
<p>El usuario puede crear sus propias <strong>cadenas</strong> dentro de cada <strong>tabla</strong> para organizar reglas. Las reglas se ejecutan de manera <strong>secuencial</strong> y tienen una <strong>jerarquía</strong>, la última es la que prevalece sobre la anterior, por lo que si en una deniego el acceso a por ejemplo un protocolo en específico y en la siguiente lo habilito será posible hacer uso de ese protocolo.</p>
<h3>Parámetros comunes de iptables:</h3>
<ul>
<li><code>iptables -A</code>: Append, añadir una regla.</li>
<li><code>iptables -D</code>: Borrar una regla.</li>
<li><code>iptables -F</code>: Eliminta <strong>todas</strong> las reglas. </li>
<li><code>iptables -P</code>: Modifica las políticas de una cadena.</li>
<li><code>iptables -L</code>: Lista todas las reglas.</li>
<li><code>iptables -N</code>: Crea una cadena de un usuario.</li>
<li><code>iptables -R</code>: Reemplaza una regla.</li>
<li><code>iptables -X</code>: Elimina una cadena definida por un usuario.</li>
<li><code>iptables -t &lt;table&gt;</code>: Selecciona la tabla que se va a manipular.</li>
</ul>
<p>Ejercicio: Elimina las reglas en la tabla NAT:</p>
<!--puede ser que esto no funcione-->
<details close>
<summary>Solución:</summary>
    <code>
        iptables -t nat -F
    </code>
</details>
<p><br></p>
<p>Para ver una lista de todos los argumentos que se pueden usar en <code>iptables</code> recomiendo leer el sagrado <code>man iptables</code> para buscar en profundidad algún parámetro que te haga falta o <code>iptables --help</code> para una lista de los parámetros comunes del programa.</p>
<h3>Reglas</h3>
<ul>
<li><code>-i</code>:  Interfaz de red por donde entrará el paquete. Solo se puede usar para <code>INPUT</code>, <code>FORWARD</code> y <code>PREROUTING</code>. </li>
<li><code>-o</code>:  Iterfaz de red por donde saldrá el paquete.</li>
<li><code>-s 0.0.0.0/0</code>:  Permite comparar los paquetes entrantes que vienen de una dirección. (En este caso cualquiera).</li>
<li><code>-d</code>:  Compara los paquetes salientes que llegan de la dirección de origen, la IP se puede sustituir por un hostname tanto en -s como en -d (Porque al fin y al cabo te lo va a resolver el DNS).</li>
<li><code>-p</code>:  Tipo de protocolo a usar que será comparado con la regla.</li>
<li><code>-sport</code>:  Puerto de origen. Se puede especificar un rango usando ':' ejemplo: 1090:65535</li>
<li><code>-dport</code>:  Puerto de destino.</li>
<li><code>-m</code>:  Se aplica la regla si se cumple una condición específica.</li>
<li><code>-j</code>:  Destino de la regla:</li>
</ul>
<table>
<thead>
<tr>
<th>Destino</th>
<th>Información</th>
</tr>
</thead>
<tbody>
<tr>
<td>ACCEPT</td>
<td>Acepta la conexión</td>
</tr>
<tr>
<td>DROP</td>
<td>Deniega el acceso</td>
</tr>
<tr>
<td>QUEUE</td>
<td>Envía el paquete a las reglas del usuario</td>
</tr>
<tr>
<td>REJECT</td>
<td>Rechaza la conexión y envía el paquete a su origen</td>
</tr>
</tbody>
</table>
<ul>
<li><code>LOG</code>:  Todos los paquetes que coincidan por esta regla se guardan en un log.</li>
<li><code>SNAT</code>:  Un estado virtual donde difiere si la dirección fuente original difiere del envío destinado.</li>
<li><code>DNAT</code>:  Un estado virtual donde coincide si el destino difiere del lugar donde son reenviados.</li>
</ul>
<h3>Políticas</h3>
<p>En este apartado veremos algunos ejemplos sobre como aplicar políticas en <code>iptables</code>.</p>
<ul>
<li>Denegar el tráfico entrante:
<code>iptables -P INPUT DROP</code></li>
<li>Denegar el tráfico saliente:
<code>iptables -P OUTPUT DROP</code></li>
<li>Denegar el reenvío de paquetes:
<code>iptables -P FORWARD DROP</code></li>
</ul>
<p>Eso sería todo, muchas gracias por leer,
<code>Happy Hacking!</code></p>
<p><em>Si encuentras algún error o errata házmelo saber.</em></p>
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