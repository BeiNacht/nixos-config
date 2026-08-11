find /home/alex/shared/storage/ -type f -size +10M -exec filefrag {} + | \
awk -F: '/extents found/ { \
    split($2, a, " "); \
    if (a[1] > 1000) { \
        print $1 \
    } \
}' | while read -r file; do \
    echo "Defragmenting ($(( $(filefrag "$file" | awk '{print $(NF-2)}') )) extents): $file"; \
    sudo btrfs filesystem defragment "$file"; \
done

