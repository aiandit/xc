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

  <xsl:template match="x:offer">
    <div title="Angebot" class="offer">
      <div>
        <xsl:apply-templates select="x:address"/>
        <xsl:apply-templates select="x:texts/x:sub"/>
        <xsl:apply-templates select="x:texts/x:main"/>
        <xsl:apply-templates select="x:texts/x:body"/>
        <xsl:apply-templates select="x:calculation"/>
        <xsl:apply-templates select="x:texts/x:post"/>
        <xsl:apply-templates select="x:texts/x:closing"/>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="x:body|x:closing|x:post">
    <div class="{local-name()}">
      <p>
        <xsl:apply-templates mode="to-xhtml"/>
      </p>
    </div>
  </xsl:template>

  <xsl:template match="x:main">
    <h4 style="clear: both"><xsl:value-of select="."/></h4>
  </xsl:template>

  <xsl:template match="x:sub">
    <h4 class="fright" style="clear: both"><xsl:apply-templates mode="get-text"/></h4>
    <!--       <xsl:if test="x:counter">
         <form action="/main/counter" method="post">
        <input type="hidden" value="on" name="incr"/>
        <input type="hidden" value="/t2/c1.xml" name="path"/>
        <input type="hidden" name="csrfmiddlewaretoken" value="{/*/x:cgi/x:csrfmiddlewaretoken}"/>
        <input type="submit" value="Renew Number"/>
      </form>
    </xsl:if> -->
  </xsl:template>

  <xsl:template match="x:counter" mode="get-text">
    <span class="counter"><xsl:value-of select="."/></span>
  </xsl:template>

  <xsl:template match="x:address">
    <table class="address fright" style="clear: both">
      <xsl:apply-templates/>
    </table>
  </xsl:template>

  <xsl:template match="x:address/x:*">
    <tr>
      <td>
        <xsl:apply-templates select="." mode="get-text"/>
      </td>
    </tr>
  </xsl:template>
  <xsl:template match="x:address/x:firstname">
    <tr>
      <td>
        <xsl:apply-templates select="." mode="get-text"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="../x:lastname" mode="get-text"/>
      </td>
    </tr>
  </xsl:template>
  <xsl:template match="x:address/x:name"/>
  <xsl:template match="x:address/x:lastname"/>

  <xsl:template match="x:calculation">
    <table class="calculation">
      <tr>
<!--        <td></td> -->
        <th class="aleft" colspan="2">Posten</th>
        <th class="aright">
          Anzahl
        </th>
        <th class="aright">
          Preis
        </th>
        <th class="aright">
          Gesamt
        </th>
      </tr>
      <xsl:apply-templates/>
    </table>
  </xsl:template>

  <xsl:template match="*" mode="as-price">
    <span class="price">
      <span class="number">
        <xsl:value-of select="format-number(., '0.00')"/>
      </span>
      <xsl:value-of select="../x:cur|../../x:cur"/>
    </span>
  </xsl:template>

  <xsl:template match="*" mode="as-number" name="as-number">
    <xsl:param name="cont" select="."/>
    <span class="number">
      <xsl:value-of select="number($cont)"/>
    </span>
  </xsl:template>

  <xsl:template match="x:tradeitem">
    <tr>
      <td class="aleft">
        <xsl:number format="0"/>.
      </td>
      <td>
        <xsl:value-of select="x:desc"/>
      </td>
      <td class="aright ntd">
        <xsl:apply-templates select="x:amount" mode="as-number"/>
      </td>
      <td class="aright ntd">
        <xsl:apply-templates select="x:price" mode="as-price"/>
      </td>
      <td class="aright ntd">
        <xsl:apply-templates select="x:cost" mode="as-price"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="x:sum-netto">
    <tr>
      <td>
        Netto
      </td>
      <td>
      </td>
      <td>
      </td>
      <td>
      </td>
      <td class="aright">
        <xsl:apply-templates select="." mode="as-price"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="x:sum-taxes">
    <tr>
      <td>
        USt.
        <xsl:call-template name="as-number">
          <xsl:with-param name="cont" select="../x:uststz * 100"/>
        </xsl:call-template>
        <xsl:text>%</xsl:text>
      </td>
      <td>
      </td>
      <td>
      </td>
      <td>
      </td>
      <td class="aright">
        <xsl:apply-templates select="." mode="as-price"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="x:sum-brutto">
    <tr>
      <th class="aleft">
        Brutto
      </th>
      <td>
      </td>
      <td>
      </td>
      <td>
      </td>
      <th class="aright">
        <xsl:apply-templates select="." mode="as-price"/>
      </th>
    </tr>
  </xsl:template>

</xsl:stylesheet>
