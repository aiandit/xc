<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml"/>

  <xsl:template match="text()"/>

  <xsl:template match="/">
    <div>
      <h5>Edit Offer</h5>
      <form id="xc-edit-form-real" action="/main/edit" method="POST" style="display: none;">
        <input type="text" name="path" value="{/*/cgi[1]/path}"/>
        <textarea name="data"> </textarea>
        <input type="text" name="comment"/>
        <input type="hidden" name="csrfmiddlewaretoken" value="{/*/cgi[1]/csrfmiddlewaretoken}"/>
      </form>
        <xsl:variable name="rjs">
          <xsl:apply-templates mode="renderjs"/>
        </xsl:variable>
        <xsl:variable name="jsc">
        xc.renderjs = function(ev) {
          var cf = document.forms['xc-edit-form-dummy'];
          var rf = document.forms['xc-edit-form-real'];
          var data = '' <xsl:value-of select="$rjs"/>;
          rf.data.value = data;
          rf.comment.value = cf.comment.value;
          console.log('Now submit real form:');
          console.log(data);
          console.log(rf);
          dohandleFormSubmit(rf, ev);
          return false;
          }
        </xsl:variable>
      <form id="xc-edit-form-dummy" method="POST" action="javascript:xc.renderjs">
        <xsl:apply-templates mode="render"/>
        <textarea name="comment">
        </textarea>
        <textarea name="code">
          <xsl:value-of select="$jsc"/>
        </textarea>
        <input type="submit" name="submit"/>
      </form>
      <script type="text/javascript">
        <xsl:value-of select="$jsc"/>
      </script>
    </div>
  </xsl:template>

  <xsl:template match="text()" mode="render"/>

  <xsl:template match="x:*" mode="render">
    <xsl:apply-templates select="."/>
  </xsl:template>

  <xsl:template match="x:offer|x:address">
    <xsl:if test="self::x:address">
      <span class="stag">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>&gt;</xsl:text>
      </span>
    </xsl:if>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <fieldset style="display: grid; grid-template-columns: 0.1fr auto 0.1fr;">
        <xsl:apply-templates/>
      </fieldset>
    </xsl:copy>
    <xsl:if test="self::x:address">
      <span class="etag">
        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>&gt;</xsl:text>
      </span>
    </xsl:if>
  </xsl:template>

  <xsl:template match="text()" mode="renderjs"/>

  <xsl:template match="x:offer|x:address" mode="renderjs">
    <xsl:text>+ '&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>&gt;' </xsl:text>
    <xsl:apply-templates mode="renderjs"/>
    <xsl:text> + '&lt;/</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>&gt;'</xsl:text>
  </xsl:template>

  <xsl:template match="x:street|x:name|x:city|x:country|x:postcode|
                       x:desc|x:post|x:main|x:sub" mode="renderjs">
    <xsl:text>+ '&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>&gt;' + </xsl:text>
    <xsl:text>cf.offer_</xsl:text>
    <xsl:value-of select="local-name()"/>
    <xsl:text>.value + '&lt;/</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>&gt;'</xsl:text>
  </xsl:template>

  <xsl:template match="x:desc|x:post|x:main|x:sub">
    <label for="offer-{local-name()}-{generate-id()}">
      <span class="stag">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>&gt;</xsl:text>
      </span>
    </label>
    <textarea id="offer-{local-name()}-{generate-id()}" name="offer_{local-name()}">
      <xsl:apply-templates mode="xhtml-code"/>
    </textarea>
    <label for="offer-{local-name()}-{generate-id()}">
      <span class="etag">
        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>&gt;</xsl:text>
      </span>
    </label>
  </xsl:template>

  <xsl:template match="x:street|x:name|x:city|x:country|x:postcode">
    <label for="offer-{local-name()}-{generate-id()}">
      <span class="stag">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>&gt;</xsl:text>
      </span>
    </label>
    <input id="offer-{local-name()}-{generate-id()}" name="offer_{local-name()}">
      <xsl:attribute name="value">
        <xsl:apply-templates mode="get-text"/>
      </xsl:attribute>
    </input>
    <label for="offer-{local-name()}-{generate-id()}">
      <span class="etag">
        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>&gt;</xsl:text>
      </span>
    </label>
  </xsl:template>

</xsl:stylesheet>
