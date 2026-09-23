## Java

  安装：

  brew install openjdk@21

  启动 Fuseki 前，在当前终端指定 Java 21：

  export JAVA_HOME="$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home"
  export PATH="$JAVA_HOME/bin:$PATH"

  java -version


