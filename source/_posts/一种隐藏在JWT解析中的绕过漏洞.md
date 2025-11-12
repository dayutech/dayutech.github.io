---
title: '''一种隐藏在JWT解析中的绕过漏洞'''
categories:
  - - 漏洞分析
top: 999
description: 本文展示了一种存在于JJWT中容易被忽视的绕过漏洞
abbrlink: ec714069
date: 2025-11-12 16:38:59
tags:
---
```java
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.SignatureException;

public class VulnerableJwtValidator {

    private String secret = "mySecretKey"; // 弱密钥 + 硬编码（额外风险）

    public Claims parseToken(String token) {
        // 错误1：使用 parser.parse() 而不是 parseClaimsJws()
        // 错误2：没有检查是否为 Jws（已签名）
        JwtParser parser = Jwts.parser().setSigningKey(secret);
        Jwt jwt = parser.parse(token); // ← 危险！接受 alg=none

        // 错误3：直接信任 getBody()，未验证是否为合法 JWS
        return (Claims) jwt.getBody(); // 返回伪造的 claims！
    }
}
```
在上面的代码中如果在审计时不注意很容以漏掉，虽然`parser`已经设置了`secretkey`，貌似时没有什么问题，攻击这在不知道`key`的情况下时不可能伪造`token`的，  
但危险往往就藏在这漫不经意间，如果攻击者构造的`token`设置了`alg`为`none`，那么`secretkey` 将完全失效`parse`方法调用将返回一个默认的`Jwt`对象，  
为了避免这个问题，应该增加响应类型的检查确认其为`Jws`的子类方可有效避免绕过。  
