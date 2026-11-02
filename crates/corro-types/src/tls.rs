use std::net::IpAddr;

use rcgen::{
    BasicConstraints, CertificateParams, CertifiedKey, DistinguishedName, DnType, DnValue, IsCa,
    Issuer, KeyIdMethod, KeyPair, KeyUsagePurpose, SanType, PKCS_ECDSA_P384_SHA384,
};
use time::OffsetDateTime;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error(transparent)]
    Rcgen(#[from] rcgen::Error),
    #[error(transparent)]
    Io(#[from] std::io::Error),
}

pub fn generate_ca() -> Result<CertifiedKey<KeyPair>, Error> {
    let signing_key = KeyPair::generate_for(&PKCS_ECDSA_P384_SHA384)?;
    let mut params = CertificateParams::default();

    params.key_identifier_method = KeyIdMethod::Sha384;

    let mut dn = DistinguishedName::new();
    dn.push(
        DnType::CommonName,
        DnValue::PrintableString("Corrosion Root CA".try_into()?),
    );
    params.distinguished_name = dn;
    params.is_ca = IsCa::Ca(BasicConstraints::Unconstrained);

    params.not_before = OffsetDateTime::now_utc();
    params.not_after = OffsetDateTime::now_utc() + time::Duration::days(365 * 5);

    params.key_usages = vec![KeyUsagePurpose::KeyCertSign, KeyUsagePurpose::CrlSign];
    let cert = params.self_signed(&signing_key)?;

    Ok(CertifiedKey { cert, signing_key })
}

pub fn generate_server_cert(
    ca_cert_pem: &str,
    ca_key_pem: &str,
    ip: IpAddr,
) -> Result<CertifiedKey<KeyPair>, Error> {
    let issuer = Issuer::from_ca_cert_pem(ca_cert_pem, KeyPair::from_pem(ca_key_pem)?)?;
    let signing_key = KeyPair::generate_for(&PKCS_ECDSA_P384_SHA384)?;

    let mut params = CertificateParams::default();

    params.key_identifier_method = KeyIdMethod::Sha384;

    let mut dn = DistinguishedName::new();
    dn.push(
        DnType::CommonName,
        DnValue::PrintableString("r.u.local".try_into()?),
    );
    params.distinguished_name = dn;

    params.subject_alt_names = vec![SanType::IpAddress(ip)];

    params.not_before = OffsetDateTime::now_utc();
    params.not_after = OffsetDateTime::now_utc() + time::Duration::days(365);

    let cert = params.signed_by(&signing_key, &issuer)?;

    Ok(CertifiedKey { cert, signing_key })
}

pub fn generate_client_cert(
    ca_cert_pem: &str,
    ca_key_pem: &str,
) -> Result<CertifiedKey<KeyPair>, Error> {
    let issuer = Issuer::from_ca_cert_pem(ca_cert_pem, KeyPair::from_pem(ca_key_pem)?)?;
    let signing_key = KeyPair::generate_for(&PKCS_ECDSA_P384_SHA384)?;

    let mut params = CertificateParams::default();

    params.key_identifier_method = KeyIdMethod::Sha384;

    let dn = DistinguishedName::new();
    params.distinguished_name = dn;

    params.not_before = OffsetDateTime::now_utc();
    params.not_after = OffsetDateTime::now_utc() + time::Duration::days(365);

    let cert = params.signed_by(&signing_key, &issuer)?;

    Ok(CertifiedKey { cert, signing_key })
}
