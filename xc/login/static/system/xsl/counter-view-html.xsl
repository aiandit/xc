<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:template match="text()"/>

  <xsl:template match="/">
    <div>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="x:counter">
    <div>
      <h4>Counter</h4>
      <p>
        Counter location: <a href="/main/edit?path={/*/x:cgi/x:path}"><xsl:value-of select="/*/x:cgi/x:path"/></a>
      </p>
      <p>Count: <xsl:value-of select="."/></p>

      <form action="/main/counter" method="post">
        <fieldset>
          <legend>Increment Counter</legend>
          <input type="submit" value="Increment"/>
          <br/>
          <input type="hidden" name="path" value="{/*/x:cgi/x:path}"/>
          <input type="hidden" name="csrfmiddlewaretoken" value="{/*/x:cgi/x:csrfmiddlewaretoken}"/>
          <input type="hidden" name="next_" value="edit"/>
          <input type="hidden" name="incr" value="on"/>
        </fieldset>
      </form>

    </div>
  </xsl:template>

</xsl:stylesheet>
