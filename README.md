# A simple proposal to provide DV certificates to Onion Sites

## Outline

[Onion sites](https://tools.ietf.org/html/rfc7686) provide self-authenticating network addresses which offer high assurance that a user of "onion networking" is connected to the service - strictly: to the possessor of a cryptographic private key - which they intended.

This degree of assurance in the TCP/IP network stack is provided by certificate authorities who provide various checks prior of issuance of a certificate to a website owner. Depending upon the nature of the end certificate, some or all of these checks are redundant in the Onion networking space.

Onion-networking-enabled browsers are capable of delivering most, possibly all, of their streams-based services and user experiences over onion networking; this is evidenced by work at [Facebook](https://www.facebookcorewwwi.onion/) and the [New York Times](https://www.nytimes3xbfgragh.onion/), amongst others. These sites are equipped with EV certificates issued under the terms of [Ballot 144 of the CA/Browser Forum](https://cabforum.org/2015/02/18/ballot-144-validation-rules-dot-onion-names/) which opened up official provision for onion networking.

EV certificates are not available to individual users, and DV certificates are not available to onion addresses, for many reasons not least the justifiable liability concerns of Certificate Authorities; however the increasing popularity of onion networking, combined with the increasing number of applications which mandate use of HTTPS, leads towards a bifurcation of trust: that onion addresses offer high assurance, but there is no means for that to be leveraged in the HTTPS stack unless one is an organisation and capable of purchasing an EV certificate. This situation inhibits innovation in the network stack.

Also: there are considerations of HTTP/2, that in the TCP/IP network space, a single TCP connection which has been authenticated with a certificate offering SubjectAltNames of both `foo.com` and `bar.net`, will be treated as a pre-existing connection to `bar.net` for connection reuse even if the connection was originally made with the intention of fetching a resource from `foo.com`. It is probable that this level of trust may only be viable by provision of a licensed Certificate Authority as an arbiter.

However, this does not prohibit us from offering what we believe is a viable and simple solution for in-browser trust of DV certificates for onion addresses:

## Proposal

Consider a website with the onion address `examplewebsitexx.onion` offering services at URIs such as:

* `https://examplewebsitexx.onion`
* `https://www.examplewebsitexx.onion/foo.html`
* `https://m.staging.examplewebsitexx.onion/foo/bar.mp3`

A browser will consider a DV certificate to be valid for connections to this site, if one of the two following conditions is true:

### Condition 1:

* The connection certificate is a valid DV certificate (eg: such as those created by [Filippo Valsorda's `mkcert`](https://github.com/FiloSottile/mkcert))
* **and** the certificate satisfies the standard trust rules for the webpage in question
* **and** the certificate is signed by a Certificate Authority Key which matches a root certificate that has been manually added to the local trust store

...or...

### Condition 2:

* The connection certificate is a valid DV certificate (eg: `mkcert`, again)
* **and** the certificate satisfies the standard trust rules for the webpage in question
* **but** the certificate is signed by a Certificate Authority Key that **cannot** be resolved in the local trust store
* **however** the rightmost label of **all Subject Alt Names in the certificate, without exception**, is `onion`
* **and** the rightmost two labels of **all Subject Alt Names in the certificate, without exception**, match those of the given onion site (ie: `examplewebsitexx.onion`)
* **and** no Common Name is supplied on the certificate

## Rationale

**Condition 1** has been extensively tested by the author, and is simple, obvious, and practically redundant: *it already works*. Extant web browsers do not take any special steps to avoid connections to `.onion` websites, and when connected to the Tor network they are abstracted from the network via a standard `SOCKS5` proxy which also performs name resolution, thereby obviating any DNS concerns.

**Condition 2** is novel, but conceptually simple: to validate a DV certificate fully for connecting to a given site - including, eg: failing validation if not-before / not-after date boundaries are exceeded - *except* to selectively ignore failure to validate the certificate chain / an inability to resolve the Certificate Authority Key Identifier, in the circumstances that the certificate **could only ever be used to communicate with the given onion address/sitename**. 

I believe this proposal addresses the trust requirements of binding onion addresses to TLS certificates, preventing the issues of HTTP/2 connection reuse on the basis of Onion DV-certificates, and provides a self-serve route forwards for individuals to build-out onion services, via use of tools like `mkcert`.

This proposal also (currently) leaves open a non-exclusionary role[1] for existing EV Onion Certificates: for those purposes where more than one Onion address, or a mixture of Onion Addresses and DNS Names, **must** be present in a single certificate; at first consideration this would broadly be in line with the original vision of EV certificates as being "extra validated"

## Potential FAQs

* Q: What if a "real" CA issues a DV certificate containing both Onion and DNS addresses?
  * A: They're not allowed to, but in any case if someone really wanted one they could buy a "combo" EV certificate which can contain both already
* Q: Why repeat the "rightmost label" stuff?
  * A: Mostly emphasis / to suggest a "sniff test" for implementers; plus I was vaguely wondering about the converse, viz: whether it was necessary to somehow "ban" `mkcert` users from generating their own "combo" certs, before I realised that it would be foolish, fruitless and unnecessary to do so.
* Q: Why the CN thing?
  * A: The goal of requiring no Common Name is simply to be doubly-certain regarding potential for trust leaks; this may be redundant / pointless / is a matter for consideration.
* Q: why not self-signed certs?
  * A: Self-signed certs, suck. Aside from the aspect of "an infinite hell of security popups", there is also the matter that a solution would require "OMG we need to define a standard for a self-signed Onion Cert" and endless bickering; on the other hand, the above is easy to explain and reason about.
* Q: isn't this the same as self-signed certs?
  * A: This is not the same as self-signed certs.  This merely means that you can skip DV chain validation **if** it is not already possible **and** there is no practicable benefit in doing so.
* Q: you're relying on tor to provide a secure channel here, which ends at the egress tor node with its onion address private keys, so your path from that last hop to your httpd should be over localhost
  * A: yes, but you're presuming the implementer's intention, here. This is no more of an risk than a terminate-and-forward TCP/IP load-balancer would be (is) for an EV certificate.
* Q: Doesn't this mean that the cert will be issued to a network connection, rather than a person?
  * Basically the same as LetsEncrypt, then.
* Q: why all this fuss? Why not just make self-authenticating Tor connections accept "any old certificate"?
  * Various reasons, not least of which is remaining orthogonal with upstream application expectations; you wouldn't want to connect to an random onion website and have it (via its certificate) offering to provide a HTTP/2 connection back to facebook.com, would you? Unless it was the genuine facebook onion address via Alt-Svc headers, of course...
* Q: Why do certificate authorities not issue DV certificates for onions?
  * A: many reasons, mostly due to liability: stuff like *"ZOMG v2 onion addresses are 80 bits of truncated SHA1 hash and if an attacker had a few squillions of dollars to spare then they could collide a key... and we (certificate authorities) might get sued for issuing a cert to a collided key."* - which is fair enough. One joy of the self-service approach to Onion DV keys is an "on your own head, be it" approach to liability: it is neither more, nor less, than mining and using the address in the first place.
  
- Alec Muffett, 8 Feb 2019

[1] ie: individuals can work around it by careful provision of multiple certificates
