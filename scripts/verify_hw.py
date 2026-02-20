import os

def main():
    labels_file = "test_labels.txt"
    preds_file = "hw_predictions.txt"

    # Check if files exist
    if not os.path.exists(labels_file) or not os.path.exists(preds_file):
        print("[Error] Missing prediction or label files!")
        return

    # Read ground truth labels
    with open(labels_file, "r") as f:
        ground_truth = [int(line.strip()) for line in f if line.strip()]

    # Read hardware predictions
    with open(preds_file, "r") as f:
        predictions = [int(line.strip()) for line in f if line.strip()]

    # Ensure both files have the same number of lines
    if len(ground_truth) != len(predictions):
        print(f"[Warning] Length mismatch! Labels: {len(ground_truth)}, Preds: {len(predictions)}")
        # Truncate to the shorter one for comparison
        min_len = min(len(ground_truth), len(predictions))
        ground_truth = ground_truth[:min_len]
        predictions = predictions[:min_len]

    # Calculate accuracy
    correct = sum(1 for gt, pred in zip(ground_truth, predictions) if gt == pred)
    total = len(ground_truth)
    accuracy = (correct / total) * 100

    print("========================================")
    print("      SNN Accelerator Final Report      ")
    print("========================================")
    print(f"Total Images Tested : {total}")
    print(f"Correct Predictions : {correct}")
    print(f"Hardware Accuracy   : {accuracy:.2f}%")
    print("========================================")

    # Output mismatches for debugging
    if accuracy < 100.0:
        print("\n[Debug] Mismatched Indices (First 10):")
        mismatch_count = 0
        for i, (gt, pred) in enumerate(zip(ground_truth, predictions)):
            if gt != pred:
                print(f"  Index {i:02d} -> GroundTruth: {gt}, HW_Predicted: {pred}")
                mismatch_count += 1
                if mismatch_count >= 10:
                    break

if __name__ == "__main__":
    main()