// Copyright 2024 Alişah Özcan
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
// Developer: Alişah Özcan

#include "heongpu.cuh"
#include "../example_util.h"
#include <omp.h>

int main(int argc, char* argv[])
{
    cudaSetDevice(0);

    heongpu::Parameters context(
        heongpu::scheme_type::ckks,
        heongpu::keyswitching_type::KEYSWITCHING_METHOD_I,
        heongpu::sec_level_type::none);

    size_t poly_modulus_degree = 8192;
    context.set_poly_modulus_degree(poly_modulus_degree);
    context.set_coeff_modulus({60, 50, 50, 50}, {60});
    context.generate();
    context.print_parameters();

    double scale = pow(2.0, 50);

    heongpu::RNGSeed common_seed; // automatically generate itself

    std::vector<int> shift_value = {1};

    ///////////////////////////////////////////////////////////
    ///////////// Alice Setup (Stage 1) (Phases 1) ////////////
    ///////////////////////////////////////////////////////////

    heongpu::HEKeyGenerator keygen_alice(context);
    heongpu::Secretkey secret_key_alice(context);
    keygen_alice.generate_secret_key(secret_key_alice);

    // Publickey
    heongpu::MultipartyPublickey public_key_alice(context, common_seed);
    keygen_alice.generate_multi_party_public_key_piece(public_key_alice,
                                                       secret_key_alice);

    // Relinkey
    heongpu::MultipartyRelinkey relin_key_alice_stage1(context, common_seed);
    keygen_alice.generate_multi_party_relin_key_piece(relin_key_alice_stage1,
                                                      secret_key_alice);

    // Galoiskey
    heongpu::MultipartyGaloiskey galois_key_alice(context, shift_value,
                                                  common_seed);
    keygen_alice.generate_multi_party_galios_key_piece(galois_key_alice,
                                                       secret_key_alice);

    ///////////////////////////////////////////////////////////
    ////////////// Bob Setup (Stage 1) (Phases 1) /////////////
    ///////////////////////////////////////////////////////////

    heongpu::HEKeyGenerator keygen_bob(context);
    heongpu::Secretkey secret_key_bob(context);
    keygen_bob.generate_secret_key(secret_key_bob);

    // Publickey
    heongpu::MultipartyPublickey public_key_bob(context, common_seed);
    keygen_bob.generate_multi_party_public_key_piece(public_key_bob,
                                                     secret_key_bob);

    // Relinkey
    heongpu::MultipartyRelinkey relin_key_bob_stage1(context, common_seed);
    keygen_bob.generate_multi_party_relin_key_piece(relin_key_bob_stage1,
                                                    secret_key_bob);

    // Galoiskey
    heongpu::MultipartyGaloiskey galois_key_bob(context, shift_value,
                                                common_seed);
    keygen_bob.generate_multi_party_galios_key_piece(galois_key_bob,
                                                     secret_key_bob);

    ///////////////////////////////////////////////////////////
    /////////// Charlie Setup (Stage 1) (Phases 1) ////////////
    ///////////////////////////////////////////////////////////

    heongpu::HEKeyGenerator keygen_charlie(context);
    heongpu::Secretkey secret_key_charlie(context);
    keygen_charlie.generate_secret_key(secret_key_charlie);

    heongpu::MultipartyPublickey public_key_charlie(context, common_seed);
    keygen_charlie.generate_multi_party_public_key_piece(public_key_charlie,
                                                         secret_key_charlie);

    // Relinkey
    heongpu::MultipartyRelinkey relin_key_charlie_stage1(context, common_seed);
    keygen_charlie.generate_multi_party_relin_key_piece(
        relin_key_charlie_stage1, secret_key_charlie);

    // Galoiskey
    heongpu::MultipartyGaloiskey galois_key_charlie(context, shift_value,
                                                    common_seed);
    keygen_charlie.generate_multi_party_galios_key_piece(galois_key_charlie,
                                                         secret_key_charlie);

    ///////////////////////////////////////////////////////////
    ///////////// Key Sharing (Stage 1) (Phases 1) ////////////
    ///////////////////////////////////////////////////////////

    std::vector<heongpu::MultipartyPublickey> participant_public_keys;
    participant_public_keys.push_back(public_key_alice);
    participant_public_keys.push_back(public_key_bob);
    participant_public_keys.push_back(public_key_charlie);

    std::vector<heongpu::MultipartyRelinkey> participant_relin_keys_stage1;
    participant_relin_keys_stage1.push_back(relin_key_alice_stage1);
    participant_relin_keys_stage1.push_back(relin_key_bob_stage1);
    participant_relin_keys_stage1.push_back(relin_key_charlie_stage1);

    std::vector<heongpu::MultipartyGaloiskey> participant_galois_keys;
    participant_galois_keys.push_back(galois_key_alice);
    participant_galois_keys.push_back(galois_key_bob);
    participant_galois_keys.push_back(galois_key_charlie);

    heongpu::HEKeyGenerator keygen_server(context);
    heongpu::Publickey common_public_key(context);
    keygen_server.generate_multi_party_public_key(participant_public_keys,
                                                  common_public_key);

    heongpu::MultipartyRelinkey common_relin_key_stage1(context, common_seed);
    keygen_server.generate_multi_party_relin_key(participant_relin_keys_stage1,
                                                 common_relin_key_stage1);

    heongpu::Galoiskey common_galois_key(context, shift_value);
    keygen_server.generate_multi_party_galois_key(participant_galois_keys,
                                                  common_galois_key);

    ///////////////////////////////////////////////////////////
    ///////////// Alice Setup (Stage 1) (Phases 2) ////////////
    ///////////////////////////////////////////////////////////

    // Relinkey
    heongpu::MultipartyRelinkey relin_key_alice_stage2(context, common_seed);
    keygen_alice.generate_multi_party_relin_key_piece(
        common_relin_key_stage1, relin_key_alice_stage2, secret_key_alice);

    ///////////////////////////////////////////////////////////
    ////////////// Bob Setup (Stage 1) (Phases 2) /////////////
    ///////////////////////////////////////////////////////////

    // Relinkey
    heongpu::MultipartyRelinkey relin_key_bob_stage2(context, common_seed);
    keygen_bob.generate_multi_party_relin_key_piece(
        common_relin_key_stage1, relin_key_bob_stage2, secret_key_bob);

    ///////////////////////////////////////////////////////////
    //////////// Charlie Setup (Stage 1) (Phases 2) ///////////
    ///////////////////////////////////////////////////////////

    // Relinkey
    heongpu::MultipartyRelinkey relin_key_charlie_stage2(context, common_seed);
    keygen_charlie.generate_multi_party_relin_key_piece(
        common_relin_key_stage1, relin_key_charlie_stage2, secret_key_charlie);

    ///////////////////////////////////////////////////////////
    //////////// Key Sharing (Stage 1) (Phases 2) /////////////
    ///////////////////////////////////////////////////////////

    std::vector<heongpu::MultipartyRelinkey> participant_relin_keys_stage2;
    participant_relin_keys_stage2.push_back(relin_key_alice_stage2);
    participant_relin_keys_stage2.push_back(relin_key_bob_stage2);
    participant_relin_keys_stage2.push_back(relin_key_charlie_stage2);

    heongpu::Relinkey common_relin_key(context);
    keygen_server.generate_multi_party_relin_key(participant_relin_keys_stage2,
                                                 common_relin_key_stage1,
                                                 common_relin_key);

    ///////////////////////////////////////////////////////////
    ////////////////// Alice Setup (Stage 2) //////////////////
    ///////////////////////////////////////////////////////////

    heongpu::HEEncoder encoder_alice(context);
    heongpu::HEEncryptor encryptor_alice(context, common_public_key);

    const int slot_count = poly_modulus_degree / 2;
    std::vector<double> message_alice(slot_count, 3.0);
    message_alice[0] = 1.0;
    message_alice[1] = 10.0;
    message_alice[2] = 100.0;

    display_vector(message_alice);

    heongpu::Plaintext plaintext_alice(context);
    encoder_alice.encode(plaintext_alice, message_alice, scale);

    heongpu::Ciphertext ciphertext_alice(context);
    encryptor_alice.encrypt(ciphertext_alice, plaintext_alice);

    ///////////////////////////////////////////////////////////
    /////////////////// Bob Setup (Stage 2) ///////////////////
    ///////////////////////////////////////////////////////////

    heongpu::HEEncoder encoder_bob(context);
    heongpu::HEEncryptor encryptor_bob(context, common_public_key);

    // Generate simple matrix in CPU.
    std::vector<double> message_bob(slot_count, 4.0);
    message_bob[0] = 1.0;
    message_bob[1] = 10.0;
    message_bob[2] = 100.0;

    display_vector(message_bob);

    heongpu::Plaintext plaintext_bob(context);
    encoder_bob.encode(plaintext_bob, message_bob, scale);

    heongpu::Ciphertext ciphertext_bob(context);
    encryptor_bob.encrypt(ciphertext_bob, plaintext_bob);

    ///////////////////////////////////////////////////////////
    ///////////////// Charlie Setup (Stage 2) /////////////////
    ///////////////////////////////////////////////////////////

    heongpu::HEEncoder encoder_charlie(context);
    heongpu::HEEncryptor encryptor_charlie(context, common_public_key);

    // Generate simple matrix in CPU.
    std::vector<double> message_charlie(slot_count, 5.0);
    message_charlie[0] = 1.0;
    message_charlie[1] = 10.0;
    message_charlie[2] = 100.0;

    display_vector(message_charlie);

    heongpu::Plaintext plaintext_charlie(context);
    encoder_charlie.encode(plaintext_charlie, message_charlie, scale);

    heongpu::Ciphertext ciphertext_charlie(context);
    encryptor_charlie.encrypt(ciphertext_charlie, plaintext_charlie);

    ///////////////////////////////////////////////////////////
    ///////////////// Server Setup (Stage 3) //////////////////
    ///////////////////////////////////////////////////////////

    heongpu::HEArithmeticOperator operators(context, encoder_charlie);

    heongpu::Ciphertext cipher_mult(context);
    operators.multiply(ciphertext_alice, ciphertext_bob, cipher_mult);
    operators.relinearize_inplace(cipher_mult, common_relin_key);
    operators.rescale_inplace(cipher_mult);

    heongpu::Ciphertext cipher_mult_add(context);
    operators.mod_drop_inplace(ciphertext_charlie);
    operators.add(cipher_mult, ciphertext_charlie, cipher_mult_add);

    heongpu::Ciphertext cipher_mult_add_rotate(context);
    operators.rotate_rows(cipher_mult_add, cipher_mult_add_rotate,
                          common_galois_key, 1);

    ///////////////////////////////////////////////////////////
    /////////////////// Alice Setup (Stage 4) /////////////////
    ///////////////////////////////////////////////////////////

    heongpu::HEDecryptor decryptor_alice(context, secret_key_alice);

    heongpu::Ciphertext partial_ciphertext_alice(context);
    decryptor_alice.multi_party_decrypt_partial(
        cipher_mult_add, secret_key_alice, partial_ciphertext_alice);

    ///////////////////////////////////////////////////////////
    /////////////////// Bob Setup (Stage 4) ///////////////////
    ///////////////////////////////////////////////////////////

    heongpu::HEDecryptor decryptor_bob(context, secret_key_alice);

    heongpu::Ciphertext partial_ciphertext_bob(context);
    decryptor_bob.multi_party_decrypt_partial(cipher_mult_add, secret_key_bob,
                                              partial_ciphertext_bob);

    ///////////////////////////////////////////////////////////
    ///////////////// Charlie Setup (Stage 4) /////////////////
    ///////////////////////////////////////////////////////////

    heongpu::HEDecryptor decryptor_charlie(context, secret_key_alice);

    heongpu::Ciphertext partial_ciphertext_charlie(context);
    decryptor_charlie.multi_party_decrypt_partial(
        cipher_mult_add, secret_key_charlie, partial_ciphertext_charlie);

    ///////////////////////////////////////////////////////////

    std::vector<heongpu::Ciphertext> partial_ciphertexts;
    partial_ciphertexts.push_back(partial_ciphertext_alice);
    partial_ciphertexts.push_back(partial_ciphertext_bob);
    partial_ciphertexts.push_back(partial_ciphertext_charlie);

    heongpu::Plaintext plaintext_result(context);
    decryptor_alice.multi_party_decrypt_fusion(partial_ciphertexts,
                                               plaintext_result);

    std::vector<double> check_result;
    encoder_alice.decode(check_result, plaintext_result);

    display_vector(check_result);

    return EXIT_SUCCESS;
}
